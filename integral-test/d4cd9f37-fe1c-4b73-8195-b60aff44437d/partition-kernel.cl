/*
 * The goal of this kernel is to create a range of values which will be used to
 * calculate an exponential function integral.
 */
 
__kernel void partitionData(
    __global float* input,
    unsigned int dataSize,
    unsigned int partsCount,
    __global float* output,
    unsigned int outputSize)
{ 
    // Get the index of the current element to be processed:
    //int id = get_global_id(0);
    // Get the number of data items per processing thread:
    //int actualItemsCount = outputSize / sizeof(float);
    //int itemsPerThread = actualItemsCount / get_global_size(0);
    
    // Create a range of input values:
    /*for (int i = 0; i < itemsPerThread; i++) {
        int idx = (id*itemsPerThread)+i;
        output[idx] = input[idx];
    }*/

    int totalOutputSize = outputSize * partsCount;
    int processedSize = dataSize < totalOutputSize ? dataSize : totalOutputSize;

    for (int i = 0; i < processedSize; i++) {
        //int idx = (id*itemsPerThread)+i;
        output[i] = input[i];
    }
}
