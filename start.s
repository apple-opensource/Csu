/*
 * Copyright (c) 1999-2006 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Portions Copyright (c) 1999 Apple Computer, Inc.  All Rights
 * Reserved.  This file contains Original Code and/or Modifications of
 * Original Code as defined in and that are subject to the Apple Public
 * Source License Version 1.1 (the "License").  You may not use this file
 * except in compliance with the License.  Please obtain a copy of the
 * License at http://www.apple.com/publicsource and read it before using
 * this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#if __ppc__ && __DYNAMIC__
//
// Force stub section next to __text section to minimize chance that
// a bl to a stub will be out of range.
//
	.text
	.symbol_stub
	.picsymbol_stub
#endif

/*
 * C runtime startup for ppc, ppc64, i386, x86_64
 *
 * Kernel sets up stack frame to look like:
 *
 *	       :
 *	| STRING AREA |
 *	+-------------+
 *	|      0      |	
 *	+-------------+	
 *	|  exec_path  | extra "apple" parameters start after NULL terminating env array
 *	+-------------+
 *	|      0      |
 *	+-------------+
 *	|    env[n]   |
 *	+-------------+
 *	       :
 *	       :
 *	+-------------+
 *	|    env[0]   |
 *	+-------------+
 *	|      0      |
 *	+-------------+
 *	| arg[argc-1] |
 *	+-------------+
 *	       :
 *	       :
 *	+-------------+
 *	|    arg[0]   |
 *	+-------------+
 *	|     argc    | argc is always 4 bytes long, even in 64-bit architectures
 *	+-------------+ <- sp
 *
 *	Where arg[i] and env[i] point into the STRING AREA
 */

	.text
	.globl start
	.align 2

#if __ppc__
start:	mr      r26,r1              ; save original stack pointer into r26
	subi	r1,r1,4		    ; make space for linkage
	clrrwi	r1,r1,5             ; align to 32 bytes (good enough for 32- and 64-bit APIs)
	li      r0,0                ; load 0 into r0
	stw     r0,0(r1)            ; terminate initial stack frame
	stwu	r1,-64(r1)	    ; allocate minimal stack frame
	lwz     r3,0(r26)           ; get argc into r3
	addi    r4,r26,4	    ; get argv into r4
	addi	r27,r3,1            ; calculate argc + 1 into r27
	slwi	r27,r27,2	    ; calculate (argc + 1) * sizeof(char *) into r27
	add     r5,r4,r27           ; get address of env[0] into r5
	bl	__start		    ; 24-bt branch to __start.  ld64 will make a branch island if needed
	trap                        ; should never return
#endif // __ppc__ 


#if __ppc64__
start:	mr      r26,r1              ; save original stack pointer into r26
	subi	r1,r1,8		    ; make space for linkage
	clrrdi	r1,r1,5             ; align to 32 bytes (good enough for 32- and 64-bit APIs)
	li      r0,0                ; load 0 into r0
	std     r0,0(r1)            ; terminate initial stack frame
	stdu	r1,-128(r1)	    ; allocate minimal stack frame
	lwz     r3,0(r26)           ; get argc into r3
	addi    r4,r26,8	    ; get argv into r4
	addi	r27,r3,1            ; calculate argc + 1 into r27
	sldi	r27,r27,3	    ; calculate (argc + 1) * sizeof(char *) into r27
	add     r5,r4,r27           ; get address of env[0] into r5
	bl	__start		    ; 24-bt branch to __start.  ld64 will make a branch island if needed
	trap                        ; should never return
#endif	// __ppc64__


#if __i386__
start:	pushl	$0		    # push a zero for debugger end of frames marker
	movl	%esp,%ebp	    # pointer to base of kernel frame
	andl    $-16,%esp	    # force SSE alignment
	subl    $16,%esp	    # room for new argc, argv, & envp, SSE aligned
	movl	4(%ebp),%ebx	    # pickup argc in %ebx
	movl	%ebx,0(%esp)	    # argc to reserved stack word
	lea	8(%ebp),%ecx	    # addr of arg[0], argv, into %ecx
	movl	%ecx,4(%esp)	    # argv to reserved stack word
	addl	$1,%ebx		    # argc + 1 for zero word
	sall	$2,%ebx		    # * sizeof(char *)
	addl	%ecx,%ebx	    # addr of env[0], envp, into %ebx
	movl	%ebx,8(%esp)	    # envp to reserved stack word
	call	__start		    # call _start(argc, argv, envp)
	hlt			    # should never return
#endif // __i386__ 



#if __x86_64__
start:	pushq	$0		    # push a zero for debugger end of frames marker
	movq	%rsp,%rbp	    # pointer to base of kernel frame
	andq    $-16,%rsp	    # force SSE alignment
	movq	8(%rbp),%rdi	    # put argc in %rdi
	leaq	16(%rbp),%rsi	    # addr of arg[0], argv, into %rsi
	movl	%edi,%edx	    # copy argc into %rdx
	addl	$1,%edx		    # argc + 1 for zero word
	sall	$3,%edx		    # * sizeof(char *)
	addq	%rsi,%rdx	    # addr of env[0], envp, into %rdx
	call	__start		    # call _start(argc, argv, envp)
	hlt			    # should never return
#endif // __x86_64__ 


// This code has be written to allow dead code stripping
	.subsections_via_symbols
