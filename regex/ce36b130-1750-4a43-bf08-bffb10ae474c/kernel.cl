#define MAX_WILDCARD 100
#define MAX_WILDCARD_CNT 10
#define MAX_STACK MAX_WILDCARD * MAX_WILDCARD_CNT 

#define MIN(a, b) (((a) < (b)) ? (a) : (b))

struct PreviewObject {
        float f1;
        float f2;
        float f3;
};

typedef struct MatchCase {
    __global char *haystack;
    int haystackSize;
    __global char *needle;
    int needleSize;
} MatchCase;

typedef struct
{
//    __local MatchCase *stackData;
    MatchCase *stackData;
    int ptr;
} CaseStack;
 
//void stackInit(CaseStack *stack, __local MatchCase* stackData)
void stackInit(CaseStack *stack, MatchCase* stackData)
{
    stack->stackData = stackData;
    stack->ptr = 0;
}
 
void stackPush(CaseStack *stack, MatchCase value)
{
// TODO: report stack overflow
//    if(stack->stackSize < MAX_STACK)
    {
        stack->stackData[stack->ptr] = value;
        stack->ptr++;
    }
}
 
MatchCase stackPop(CaseStack *stack)
{
    if(stack->ptr == 0)
    {
	MatchCase nullCase;
	nullCase.haystack = 0;
	return nullCase;
    }
    stack->ptr--;
    return stack->stackData[stack->ptr];
}

int countWildcards(__global char *needle, int needleSize) {
    int cnt = 0;
    for(int i = 0; i != needleSize; i++)
	if(needle[i] == '*')
            cnt++;
    return cnt;
}

int match(MatchCase matchCase, CaseStack *stack, __global char *maxHaystack) {
    __global char *haystack = matchCase.haystack;
    int haystackSize = matchCase.haystackSize;
    __global char *needle = matchCase.needle;
    int needleSize = matchCase.needleSize;

    __global char *s1, *s2;
    int haystackInd, needleInd;

    if(!*needle) return 0;    
    // FIXME (somehow sometimes it exceeds, why?):
    if(s1 > maxHaystack - MAX_STACK) return 0;

    s1 = haystack;
    haystackInd = 0;
    s2 = needle;
    needleInd = 0;

    while(haystackInd != haystackSize && needleInd != needleSize && *s1 == *s2) {
        s1++;
        s2++;
        haystackInd++;
        needleInd++;
    }

    if(needleInd == needleSize) return 1;
    else if(*s2 == '*') {
	MatchCase newCase;
	newCase.needle = s2 + 1;
	newCase.needleSize = needleSize - needleInd - 1;

	for(int i = 0; i != MAX_WILDCARD && haystackInd + i != haystackSize; i++) {
	    newCase.haystack = s1 + i;
	    newCase.haystackSize = haystackSize - haystackInd - i;
	    stackPush(stack, newCase);		
        }
    }
    return 0;
}

__kernel void processData(
    __global char* input,
    unsigned int dataSize,
    __global int* output,
    unsigned int outputSize,
    __global struct PreviewObject *previewBuffer)
{
    int globalSize = get_global_size(0);
    int id = get_global_id(0);

    int haystackSize = ((__global int*)input)[0];
    int needleSize = ((__global int*)input)[1];

    __global char *haystack = (__global char*) ((__global int*)input + 2);
    __global char *needle = haystack + haystackSize;

    int maxNeedleSize = needleSize + countWildcards(needle, needleSize) * (MAX_WILDCARD - 1);

    __global char *subHaystack = haystack + id * haystackSize / globalSize;
    int subHaystackSize = haystackSize / globalSize + ((id == globalSize - 1) ? haystackSize%globalSize : maxNeedleSize - 1);
    int sizeLimit = haystackSize - id * (haystackSize / globalSize);
    if(subHaystackSize > sizeLimit) subHaystackSize = sizeLimit;
    int subHaystackOffsetSize = haystackSize / globalSize + ((id == globalSize - 1) ? haystackSize%globalSize : 0);

    CaseStack stack;
//    __local MatchCase stackData[MAX_STACK];
    MatchCase stackData[MAX_STACK];
    stackInit(&stack, stackData);

    output[id] = 0;

    __global char*maxHaystack = haystack + haystackSize;

    __global char *cp = subHaystack;
    for(int offset = 0; offset != subHaystackOffsetSize; offset++) {
    	MatchCase initialCase;
    	initialCase.haystack = cp;
    	initialCase.haystackSize = subHaystackSize - offset;
    	initialCase.needle = needle;
    	initialCase.needleSize = needleSize;

	stackPush(&stack, initialCase);

    	MatchCase nextCase = stackPop(&stack);
    	while(nextCase.haystack != 0) {
		output[id] += match(nextCase, &stack, maxHaystack);
		nextCase = stackPop(&stack);
    	}

        cp++;
    }

/*
    barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
    // summing the results
    if(id == 0) {
	int sum = 0;
	for(int i = 0; i != globalSize; i++) 
	    sum += output[i];
    	output[0] = sum;
    }
    */
}