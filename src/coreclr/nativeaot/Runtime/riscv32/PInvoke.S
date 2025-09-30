// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#include <unixasmmacros.inc>
#include "AsmOffsets.inc"

.global RhpTrapThreads

//
// RhpPInvoke
//
// IN:  a0: address of pinvoke frame
//
// This helper assumes that its callsite is as good to start the stackwalk as the actual PInvoke callsite.
// The code generator must treat the callsite of this helper as GC triggering and generate the GC info for it.
// Also, the code generator must ensure that there are no live GC references in callee saved registers.
//

NESTED_ENTRY RhpPInvoke, _TEXT, NoHandler
        sw    fp, OFFSETOF__PInvokeTransitionFrame__m_FramePointer(a0)
        sw    ra, OFFSETOF__PInvokeTransitionFrame__m_RIP(a0)
        sw    t0, OFFSETOF__PInvokeTransitionFrame__m_PreservedRegs(a0)
        li    t0, PTFF_SAVE_SP
        sw    t0, OFFSETOF__PInvokeTransitionFrame__m_Flags(a0)

        // get TLS global variable address
        // Save MethodTable pointer. INLINE_GETTHREAD will trash a0.
        mv               t2, a0
        INLINE_GETTHREAD a1

        sw    a1, OFFSETOF__PInvokeTransitionFrame__m_pThread(t2)
        sw    t2, OFFSETOF__Thread__m_pTransitionFrame(a1)
        ret
NESTED_END RhpPInvoke, _TEXT

LEAF_ENTRY RhpPInvokeReturn, _TEXT
        lw    t0, OFFSETOF__PInvokeTransitionFrame__m_pThread(a0)
        mv    t1, zero
        sw    t1, OFFSETOF__Thread__m_pTransitionFrame(t0)

        PREPARE_EXTERNAL_VAR_INDIRECT_W RhpTrapThreads, t0

        bnez    t1, 0f  // If TrapThreadsFlags_None is non-zero, branch
        ret
0:
        // passing transition frame pointer in a0
        tail    RhpWaitForGC2
LEAF_END RhpPInvokeReturn, _TEXT
