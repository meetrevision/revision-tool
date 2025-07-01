#include <stdio.h>
#include <windows.h>
#include <tlhelp32.h>
#include <wchar.h>
#include <stdlib.h>

/**
 * Checks if a process with the given name is currently running
 * @param processName Name of the process to check (including .exe extension)
 * @return 1 if process is running, 0 if not running, -1 on error
 */
__declspec(dllexport) int IsRunning(const wchar_t* processName) {
    HANDLE hProcessSnap;
    PROCESSENTRY32 pe32;

    if (processName == NULL) {
        fprintf(stderr, "Invalid process name (NULL).\n");
        return -1;
    }

    hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap == INVALID_HANDLE_VALUE) {
        fprintf(stderr, "CreateToolhelp32Snapshot failed with error: %lu.\n", GetLastError());
        return -1;
    }

    pe32.dwSize = sizeof(PROCESSENTRY32);

    if (!Process32First(hProcessSnap, &pe32)) {
        fprintf(stderr, "Process32First failed with error: %lu.\n", GetLastError());
        CloseHandle(hProcessSnap);
        return -1;
    }

    do {
        wchar_t exeFile[MAX_PATH];
        if (MultiByteToWideChar(CP_UTF8, 0, pe32.szExeFile, -1, exeFile, MAX_PATH) == 0) {
            fprintf(stderr, "MultiByteToWideChar failed with error: %lu.\n", GetLastError());
            continue;
        }
        
        if (wcscmp(exeFile, processName) == 0) {
            CloseHandle(hProcessSnap);
            return 1;
        }
    } while (Process32Next(hProcessSnap, &pe32));

    CloseHandle(hProcessSnap);
    return 0;
}