/*
 * The goal of this kernel is to calculate the the fields of rectangles which
 * approximate the integral value.
 */
struct PreviewObject {
	float f1;
	float f2;
	float f3;
};

inline float f(int x) {
	return (float)x * (float)x / 100.0;
}

__kernel void processData(
    __global float* input,
    unsigned int dataSize,
    __global float* output,
    unsigned int outputSize,
    __global struct PreviewObject *previewBuffer)
{ 
    // Get the index of the current element to be processed
    int id = get_global_id(0);
    // Get the number of data items per processing thread
    int actualItemsCount = outputSize / sizeof(float);
    int itemsPerThread = actualItemsCount / get_global_size(0);
 
    // Get the delta between values:   

    int i = 0;
    if(id == 0) {
    	   i = 1;
    }
    
    // Calculate the fields:
    for (;i < itemsPerThread; i++) {
        int idx = (id*itemsPerThread) + i - 1;
        
	   // Get the delta between values:   
        float delta = input[idx + 1] - input[idx];
	   float y = f(input[idx]) * delta;

        output[idx] = y;
        previewBuffer[idx].f1 = input[idx];
        previewBuffer[idx].f2 = delta;
        previewBuffer[idx].f3 = y;
    }        
}