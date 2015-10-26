#include <algorithm>
#include <cassert>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <iterator>
#include <vector>

using namespace std;

/// \file buffer-in-vector.cpp
///
/// Shows how to use the data() of a vector as a working area for C
/// funtions. The examples is with Cstrings, however, it is more useful when
/// the buffer is used by a Unix syscall, like read() or write()

vector<char> wrap_in_vector(const char* cstring)
{
	if (!cstring) return vector<char>(); // same as for ""

	size_t len = strlen(cstring);
	vector<char> result(len);

	// next line could be read(fd, result.data(), len)
	strncpy(result.data(), cstring, len);
	assert(result.capacity() == len);
	assert(result.size() == len);

	return result;
}

void test_cstring(const char* cstring)
{
	cout << "\"" << (cstring ? cstring : "NULL") << "\"\t";
	vector<char> vec { wrap_in_vector(cstring) };

	copy(vec.begin(), vec.end(), ostream_iterator<char>(cout, ", "));
	cout << endl;
}

int main(int argc, char **argv)
{
	for (int i = 1; i < argc; ++i) {
		test_cstring(argv[i]);
	}

	test_cstring(nullptr);
}

/// Local Variables:
/// compile-command: "time -p LANG=C clang++ -o binv buffer-in-vector.cpp -g3 -O0 -std=c++11"
/// End:
