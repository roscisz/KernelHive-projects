#define DEG_TO_RAD 0.017453292519943295769236907684886
#define EARTH_RADIUS_IN_METERS 6372797.560856
#define POW_PAR 2

struct PreviewObject {
        float f1;
        float f2;
        float f3;
};

/**
* Uses the haversine formula to calculate the great circle
* distance between two points given by decimal degrees
*/
float dist(float fromLat, float fromLon, float toLat, float toLon) {
	float latArc = ((float) (fromLat - toLat)) * DEG_TO_RAD;
	float lonArc = ((float) (fromLon - toLon)) * DEG_TO_RAD;
	float latH = sin(latArc * 0.5);
	float lonH = sin(lonArc * 0.5);
	float tmp = cos(fromLat * DEG_TO_RAD) * cos(toLat * DEG_TO_RAD);
	return 2.0 * asin(sqrt(latH*latH + tmp*lonH*lonH)) * EARTH_RADIUS_IN_METERS;
}

__kernel void processData(
    __global char* input,
    unsigned int dataSize,
    __global float* output,
    unsigned int outputSize,
    __global struct PreviewObject *previewBuffer)
{
    int globalSize = get_global_size(0);
    int id = get_global_id(0);

    __global int *ints = (__global int *) input;
    int width = ints[0];
    int height = ints[1];
    int nMsrmnts = ints[2];

    __global float *floats = (__global float*) ints + 3;
    float gLat = floats[0];
    float gLon = floats[1];
    float latPerPx = floats[2];
    float lonPerPx = floats[3];

    __global float *msrmnts = floats + 4;

    int size = width * height;

    int x, y;
    float lat, lon;
    for(int i = id; i < size; i += globalSize) {
	x = i / width;
	y = i % width;

	lat = gLat + x * latPerPx;
	lon = gLon + y * lonPerPx;

	float sVals = 0.0, sWeights = 0.0, d, w;
	for(int j = 0; j != nMsrmnts; j++) {
		d = dist(lat, lon, msrmnts[j * 3 + 0], msrmnts[j * 3 + 1]);
		w = 1.0 / (pow(d, POW_PAR));
		sVals += w * msrmnts[j * 3 + 2];
		sWeights += w;
	}
	
	output[i] = sVals/sWeights;
    }
}
