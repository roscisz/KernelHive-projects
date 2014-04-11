#include <CL/cl.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CL_CHECK(_expr)                                                         \
   do {                                                                         \
     cl_int _err = _expr;                                                       \
     if (_err == CL_SUCCESS)                                                    \
       break;                                                                   \
     fprintf(stderr, "OpenCL Error: '%s' returned %d!\n", #_expr, (int)_err);   \
     abort();                                                                   \
   } while (0)

#define CL_CHECK_ERR(_expr)                                                     \
   ({                                                                           \
     cl_int _err = CL_INVALID_VALUE;                                            \
     typeof(_expr) _ret = _expr;                                                \
     if (_err != CL_SUCCESS) {                                                  \
       fprintf(stderr, "OpenCL Error: '%s' returned %d!\n", #_expr, (int)_err); \
       abort();                                                                 \
     }                                                                          \
     _ret;                                                                      \
   })

void pfn_notify(const char *errinfo, const void *private_info, size_t cb, void *user_data)
{
	fprintf(stderr, "OpenCL Error (via pfn_notify): %s\n", errinfo);
}

void pfn_notify2(cl_program a, void *user_data)
{
	fprintf(stderr, "OpenCL Error (via pfn_notify2): %s\n", user_data);
}

int main(int argc, char **argv)
{
	if(argc < 2) {
	    printf("%s <regex>\n", argv[0]);
	    return 1;
	}

	cl_platform_id platforms[100];
	cl_uint platforms_n = 0;
	CL_CHECK(clGetPlatformIDs(100, platforms, &platforms_n));

	if (platforms_n == 0)
		return 1;

	cl_device_id devices[100];
	cl_uint devices_n = 0;
	CL_CHECK(clGetDeviceIDs(platforms[0], CL_DEVICE_TYPE_CPU, 100, devices, &devices_n));

	if (devices_n == 0)
		return 1;

	cl_context context;
	context = CL_CHECK_ERR(clCreateContext(NULL, 1, devices, &pfn_notify, NULL, &_err));

	FILE* programHandle = fopen("ce36b130-1750-4a43-bf08-bffb10ae474c/kernel.cl", "r");
	fseek(programHandle, 0, SEEK_END);
	size_t programSize = ftell(programHandle);

	rewind(programHandle);
	 
	char *programBuffer = (char*) malloc(programSize + 1);
	programBuffer[programSize] = '\0';
	fread(programBuffer, sizeof(char), programSize, programHandle);
	fclose(programHandle);

	cl_program program;
	program = CL_CHECK_ERR(clCreateProgramWithSource(context, 1, (const char **) &programBuffer, &programSize, &_err));
	if (clBuildProgram(program, 1, devices, "", NULL, NULL) != CL_SUCCESS) {
		char buffer[10240];
		clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, NULL);
		fprintf(stderr, "CL Compilation failed:\n%s", buffer);
		abort();
	}
	CL_CHECK(clUnloadCompiler());

	free(programBuffer);

	FILE *haystackHandle = fopen("data", "r");
	fseek(haystackHandle, 0, SEEK_END);
	int haystackSize = ftell(haystackHandle) - 1;

	rewind(haystackHandle);
	
	char *haystackBuffer = (char*) malloc(haystackSize);
	fread(haystackBuffer, sizeof(char), haystackSize, haystackHandle);
	fclose(haystackHandle);
//	printf("%d: %s\n", haystackSize, haystackBuffer);
	printf("%d\n", haystackSize);

	const char *needleBuffer = argv[1];
	int needleSize = strlen(needleBuffer);
//	printf("%d: %s\n", needleSize, needleBuffer);

	cl_mem input_buffer;
	int input_buffer_size = 2*sizeof(int) + sizeof(char) * (haystackSize + needleSize);
	input_buffer = CL_CHECK_ERR(clCreateBuffer(context, CL_MEM_READ_ONLY, input_buffer_size, NULL, &_err));

	cl_mem output_buffer;
	size_t nCores = 512;
	int output_buffer_size = nCores * sizeof(int);
	output_buffer = CL_CHECK_ERR(clCreateBuffer(context, CL_MEM_WRITE_ONLY, output_buffer_size, NULL, &_err));

	cl_kernel kernel;
	kernel = CL_CHECK_ERR(clCreateKernel(program, "processData", &_err));

	CL_CHECK(clSetKernelArg(kernel, 0, sizeof(input_buffer), &input_buffer));
	CL_CHECK(clSetKernelArg(kernel, 1, sizeof(input_buffer_size), &input_buffer_size));
	CL_CHECK(clSetKernelArg(kernel, 2, sizeof(output_buffer), &output_buffer));
	CL_CHECK(clSetKernelArg(kernel, 3, sizeof(output_buffer_size), &output_buffer_size));
	int fakePreview;
        CL_CHECK(clSetKernelArg(kernel, 4, sizeof(int), &fakePreview));


	cl_command_queue queue;
	queue = CL_CHECK_ERR(clCreateCommandQueue(context, devices[0], 0, &_err));

	CL_CHECK(clEnqueueWriteBuffer(queue, input_buffer, CL_TRUE, 0, sizeof(haystackSize), &haystackSize, 0, NULL, NULL));
	CL_CHECK(clEnqueueWriteBuffer(queue, input_buffer, CL_TRUE, sizeof(haystackSize), sizeof(needleSize), &needleSize, 0, NULL, NULL));
	CL_CHECK(clEnqueueWriteBuffer(queue, input_buffer, CL_TRUE, sizeof(haystackSize) + sizeof(needleSize), haystackSize, haystackBuffer, 0, NULL, NULL));
	CL_CHECK(clEnqueueWriteBuffer(queue, input_buffer, CL_TRUE, sizeof(haystackSize) + sizeof(needleSize) + haystackSize, needleSize, needleBuffer, 0, NULL, NULL));

	cl_event kernel_completion;
	size_t global_work_size[3] = { 1, 1, 1 };
	size_t local_work_size[3] = { 1, 1, 1 };
	CL_CHECK(clEnqueueNDRangeKernel(queue, kernel, 1, NULL, global_work_size, local_work_size, 0, NULL, &kernel_completion));
	CL_CHECK(clWaitForEvents(1, &kernel_completion));
	CL_CHECK(clReleaseEvent(kernel_completion));

	printf("Result:");
//		int data[nCores];
		int data;
	        CL_CHECK(clEnqueueReadBuffer(queue, output_buffer, CL_TRUE, 0, sizeof(int), &data, 0, NULL, NULL));
                printf(" %d", data);
/*
		CL_CHECK(clEnqueueReadBuffer(queue, output_buffer, CL_TRUE, 0, nCores * sizeof(int), data, 0, NULL, NULL));
		int i;
		for(i = 0; i != 1; i++) 
		    printf("%d: %d\n", i, data[i]);
*/
	printf("\n");

	free(haystackBuffer);

	CL_CHECK(clReleaseMemObject(input_buffer));
	CL_CHECK(clReleaseMemObject(output_buffer));

	CL_CHECK(clReleaseKernel(kernel));
	CL_CHECK(clReleaseProgram(program));
	CL_CHECK(clReleaseContext(context));

	return 0;
}
