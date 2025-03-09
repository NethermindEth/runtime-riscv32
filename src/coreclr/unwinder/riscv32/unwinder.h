// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

//

#ifndef __unwinder_riscv32__
#define __unwinder_riscv32__

#include "baseunwinder.h"

//---------------------------------------------------------------------------------------
//
// See the comment for the base class code:OOPStackUnwinder.
//

class OOPStackUnwinderRISCV32 : public OOPStackUnwinder
{
public:
    // Unwind the given CONTEXT to the caller CONTEXT.  The CONTEXT will be overwritten.
    BOOL Unwind(T_CONTEXT * pContext);

    //
    // Everything below comes from dbghelp.dll.
    //

protected:
    HRESULT UnwindPrologue(_In_ DWORD ImageBase,
                           _In_ DWORD ControlPc,
                           _In_ DWORD FrameBase,
                           _In_ _PIMAGE_RUNTIME_FUNCTION_ENTRY FunctionEntry,
                           __inout PT_CONTEXT ContextRecord);

    HRESULT VirtualUnwind(_In_ DWORD ImageBase,
                          _In_ DWORD ControlPc,
                          _In_ _PIMAGE_RUNTIME_FUNCTION_ENTRY FunctionEntry,
                          __inout PT_CONTEXT ContextRecord,
                          _Out_ PDWORD EstablisherFrame);

    DWORD64 LookupPrimaryUnwindInfo
        (_In_ _PIMAGE_RUNTIME_FUNCTION_ENTRY FunctionEntry,
         _In_ DWORD ImageBase,
         _Out_ _PIMAGE_RUNTIME_FUNCTION_ENTRY PrimaryEntry);

    _PIMAGE_RUNTIME_FUNCTION_ENTRY SameFunction
        (_In_ _PIMAGE_RUNTIME_FUNCTION_ENTRY FunctionEntry,
         _In_ DWORD ImageBase,
         _In_ DWORD ControlPc,
         _Out_ _PIMAGE_RUNTIME_FUNCTION_ENTRY FunctionReturnBuffer);
};

#endif // __unwinder_riscv32__
