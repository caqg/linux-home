#include <cstdlib>
#include <iostream>
#include <vector>

using namespace std;

#ifndef BIAS
#define BIAS (1.0e8L);
#endif

#ifndef MAXD
#define MAXD (0xFFFFFFFUL);
#endif

#include <sys/time.h>
#include <sys/types.h>
#include <sys/resource.h>
#include <unistd.h>

void resource_report(ostream& logf, char const* tag)
{
	// logf << "\"" << tag << "\", " << getppid() << ", " << getpid();

	struct rusage ru;
	if (getrusage(RUSAGE_SELF, &ru) < 0) {
		cerr << "getrusage failed: " << errno << endl;
		return;
	}

	long double utime
		= ru.ru_utime.tv_sec + ru.ru_utime.tv_usec * 1.0e-6;
	logf << "UTIME: " << utime << endl;

	long double stime
		= ru.ru_stime.tv_sec + ru.ru_stime.tv_usec * 1.0e-6;
	logf << "STIME: " << stime << endl;
}


int main(int argc, char **argv)
{
	srand(time(0));
	size_t allocd_size = ((double)rand()/(double)RAND_MAX)*MAXD;
	cout << "size:\t" << allocd_size << '\n';

	vector<int> a(allocd_size, 0);

	resource_report(cout, argv[0]);

	return 0;
}

// Local Variables:
// compile-command: "c++ -o getrusage getrusage.cc -std=c++11 -g3 -O0"
// End:
