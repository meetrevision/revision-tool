#include <stdio.h>
#include <windows.h>
#include <tlhelp32.h>
#include <wchar.h>

__declspec(dllexport) int IsRunning(const wchar_t* processName) {
    HANDLE hProcessSnap;
    PROCESSENTRY32 pe32;

    hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap == INVALID_HANDLE_VALUE) {
        fprintf(stderr, "CreateToolhelp32Snapshot failed.\n");
        return 1;
    }

    pe32.dwSize = sizeof(PROCESSENTRY32);

    if (!Process32First(hProcessSnap, &pe32)) {
        fprintf(stderr, "Process32First failed.\n");
        CloseHandle(hProcessSnap);
        return 1;
    }

    do {
        wchar_t exeFile[MAX_PATH];
        MultiByteToWideChar(CP_ACP, 0, pe32.szExeFile, -1, exeFile, MAX_PATH);
        if (wcscmp(exeFile, processName) == 0) {
            CloseHandle(hProcessSnap);
            return 0; 
        }
    } while (Process32Next(hProcessSnap, &pe32));

    CloseHandle(hProcessSnap);
    return 1;
}

__declspec(dllexport) int IsRunningC(const wchar_t* processName) {
    return IsRunning(processName);
}

wchar_t* Utf8ToWstring(const char* str) {
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, str, -1, NULL, 0);
    wchar_t* wstrTo = (wchar_t*) malloc(size_needed * sizeof(wchar_t));
    MultiByteToWideChar(CP_UTF8, 0, str, -1, wstrTo, size_needed);
    return wstrTo;
}