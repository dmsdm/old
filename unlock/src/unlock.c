#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include "ntdll.h"

#define RTN_OK 0
#define RTN_USAGE 1
#define RTN_ERROR 13

HANDLE hHeap;

typedef HMODULE (WINAPI *pLoadLibrary)(LPCTSTR);
typedef FARPROC (WINAPI *pGetProcAddress)(HMODULE,LPCSTR);
typedef BOOL (WINAPI *pFreeLibrary)(HMODULE);


void DisplayError(
    LPTSTR szAPI    // pointer to failed API name
    )
{
    LPTSTR MessageBuffer;
    DWORD dwBufferLength;

    printf("%s() error!\n", szAPI);

    if(dwBufferLength=FormatMessage(
                FORMAT_MESSAGE_ALLOCATE_BUFFER |
                FORMAT_MESSAGE_FROM_SYSTEM,
                NULL,
                GetLastError(),
                GetSystemDefaultLangID(),
                (LPTSTR) &MessageBuffer,
                0,
                NULL
                ))
    {
        DWORD dwBytesWritten;

        //
        // Output message string on stderr
        //
        WriteFile(
                GetStdHandle(STD_ERROR_HANDLE),
                MessageBuffer,
                dwBufferLength,
                &dwBytesWritten,
                NULL
                );

        //
        // free the buffer allocated by the system
        //
        LocalFree(MessageBuffer);
    }
}

BOOL SetPrivilege(
    HANDLE hToken,          // access token handle
    LPCTSTR lpszPrivilege,  // name of privilege to enable/disable
    BOOL bEnablePrivilege   // to enable or disable privilege
    )
{
TOKEN_PRIVILEGES tp;
LUID luid;

if ( !LookupPrivilegeValue(
        NULL,            // lookup privilege on local system
        lpszPrivilege,   // privilege to lookup
        &luid ) )        // receives LUID of privilege
{
    printf("LookupPrivilegeValue error: %u\n", GetLastError() );
    return FALSE;
}

tp.PrivilegeCount = 1;
tp.Privileges[0].Luid = luid;
if (bEnablePrivilege)
    tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
else
    tp.Privileges[0].Attributes = 0;

// Enable the privilege or disable all privileges.

if ( !AdjustTokenPrivileges(
       hToken,
       FALSE,
       &tp,
       sizeof(TOKEN_PRIVILEGES),
       (PTOKEN_PRIVILEGES) NULL,
       (PDWORD) NULL) )
{
      printf("AdjustTokenPrivileges error: %u\n", GetLastError() );
      return FALSE;
}

if (GetLastError() == ERROR_NOT_ALL_ASSIGNED)

{
      printf("The token does not have the specified privilege. \n");
      return FALSE;
}

return TRUE;
}

PVOID GetInfoTable(
          IN ULONG ATableType
          )
{
    ULONG    mSize = 0x8000;
    PVOID    mPtr;
    NTSTATUS status;
    do
    {
        mPtr = HeapAlloc(hHeap, 0, mSize);

        if (!mPtr) return NULL;

        memset(mPtr, 0, mSize);

        status = NtQuerySystemInformation(ATableType, mPtr, mSize, NULL);

        if (status == STATUS_INFO_LENGTH_MISMATCH)
        {
            HeapFree(hHeap, 0, mPtr);
            mSize = mSize * 2;
        }

    } while (status == STATUS_INFO_LENGTH_MISMATCH);

    if (NT_SUCCESS(status)) return mPtr;

    HeapFree(hHeap, 0, mPtr);

    return NULL;
}

UCHAR GetFileHandleType()
{
    HANDLE                     hFile;
    PSYSTEM_HANDLE_INFORMATION Info;
    ULONG                      r;
    UCHAR                      Result = 0;

    hFile = CreateFile("NUL", GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, 0);

    if (hFile != INVALID_HANDLE_VALUE)
    {
        Info = GetInfoTable(SystemHandleInformation);

        if (Info)
        {
            for (r = 0; r < Info->uCount; r++)
            {
                if (Info->aSH[r].Handle == (USHORT)hFile &&
                    Info->aSH[r].uIdProcess == GetCurrentProcessId())
                {
                    Result = Info->aSH[r].ObjectType;
                    break;
                }
            }

            HeapFree(hHeap, 0, Info);
        }

        CloseHandle(hFile);
    }
    return Result;
}


typedef struct _NM_INFO
{
    HANDLE  hFile;
    FILE_NAME_INFORMATION Info;
    WCHAR Name[MAX_PATH];
} NM_INFO, *PNM_INFO;

DWORD WINAPI
  GetFileNameThread(PVOID lpParameter)
{
    PNM_INFO        NmInfo = lpParameter;
    IO_STATUS_BLOCK IoStatus;

    NtQueryInformationFile(NmInfo->hFile, &IoStatus, &NmInfo->Info,
                          sizeof(NM_INFO) - sizeof(HANDLE), FileNameInformation);

    return 0;
}

void GetFileName(HANDLE hFile, PCHAR TheName)
{
    HANDLE   hThread;
    PNM_INFO Info = HeapAlloc(hHeap, 0, sizeof(NM_INFO));

    Info->hFile = hFile;

    hThread = CreateThread(NULL, 0, GetFileNameThread, Info, 0, NULL);

    if (WaitForSingleObject(hThread, 50) == WAIT_TIMEOUT) TerminateThread(hThread, 0);

    CloseHandle(hThread);

    memset(TheName, 0, MAX_PATH);

    WideCharToMultiByte(CP_ACP, 0, Info->Info.FileName, Info->Info.FileNameLength >> 1, TheName, MAX_PATH, NULL, NULL);

    HeapFree(hHeap, 0, Info);
}

DWORD CreateRemThread(HANDLE hProcess, HANDLE hObject)
{
HANDLE hThread = NULL;
LPVOID pFunc = NULL;
HMODULE hkernel32;
DWORD dwError;
DWORD dwThreadId;
FARPROC close_handle;

if(!hProcess)
goto cleanup;

hkernel32 = GetModuleHandle("kernel32.dll");

if(!hkernel32)
goto cleanup;

//printf("GetModuleHandle succeeded!\n");


close_handle = GetProcAddress(hkernel32, "CloseHandle");
if (!close_handle)
goto cleanup;

//printf("GetProcAddress succeeded! err: %lu\n", GetLastError());

hThread = CreateRemoteThread(hProcess, 0, 0, (LPTHREAD_START_ROUTINE) close_handle, hObject, 0, &dwThreadId);
if(hThread == NULL)
goto cleanup;

//printf("CreateRemoteThread succeeded!\n");

cleanup:
dwError = GetLastError();
//printf("htread %lu  error: %lu\n", hThread,dwError);

if(hProcess)
{
if(hThread) CloseHandle(hThread);
CloseHandle(hProcess);
}
return dwError;
}


int main(int argc, char **argv)
{
    PSYSTEM_HANDLE_INFORMATION Info;
    ULONG                      r;
    CHAR                       Name[MAX_PATH];
    HANDLE                     hProcess, hFile;
    UCHAR                      ObFileType;
    HANDLE hThread;
    HANDLE hToken;

    int dwRetVal=RTN_OK; // assume success from main()

    printf("Win32 Unlock Utility v0.01\n\n");
    if (argc!=2) {
        printf("usage:\n%s <filename>\n%s /l - list locked files\n",argv[0],argv[0]);
                return 0;
    }

    hHeap = GetProcessHeap();

    ObFileType = GetFileHandleType();

    Info = GetInfoTable(SystemHandleInformation);

    if(!OpenThreadToken(GetCurrentThread(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, FALSE, &hToken))
        {
            if (GetLastError() == ERROR_NO_TOKEN)
            {
                if (!ImpersonateSelf(SecurityImpersonation))
                return RTN_ERROR;

                if(!OpenThreadToken(GetCurrentThread(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, FALSE, &hToken)){
                    DisplayError("OpenThreadToken");
                return RTN_ERROR;
                }
             }
            else
                return RTN_ERROR;
         }

        // enable SeDebugPrivilege
        if(!SetPrivilege(hToken, SE_DEBUG_NAME, TRUE))
        {
            DisplayError("SetPrivilege");

            // close token handle
            CloseHandle(hToken);

            // indicate failure
            return RTN_ERROR;
        }

    if (Info)
    {
        for (r = 0; r < Info->uCount; r++)
        {
            if (Info->aSH[r].ObjectType == ObFileType)
            {
                hProcess = OpenProcess(PROCESS_CREATE_THREAD|PROCESS_VM_OPERATION|PROCESS_VM_READ|PROCESS_VM_WRITE|PROCESS_DUP_HANDLE|PROCESS_QUERY_INFORMATION, FALSE, Info->aSH[r].uIdProcess);

                if (hProcess)
                {
                    if (DuplicateHandle(hProcess, (HANDLE)Info->aSH[r].Handle,
                        GetCurrentProcess(), &hFile, 0, FALSE, DUPLICATE_SAME_ACCESS))
                    {
                        GetFileName(hFile, Name);
                        if (!_stricmp(argv[1],"/l"))
                            printf("%s opened by PID:%d\n", Name, Info->aSH[r].uIdProcess);
                        else if (!_stricmp(argv[1],(Name+strlen(Name)-strlen(argv[1])))) {
//                                printf("trying createremthread\n");
                                if (!CreateRemThread(hProcess,(HANDLE)Info->aSH[r].Handle))
                                    printf("CreateRemThread failed");
                                printf("%s\n%s\n",Name+strlen(Name)-strlen(argv[1]),Name);
                            }
                        CloseHandle(hFile);
                    }
                    CloseHandle(hProcess);
                }
            }
        }
        HeapFree(hHeap, 0, Info);
    }
    return 0;
}
