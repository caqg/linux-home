//?#include <algorithm>
#include <functional>
#include <iostream>
#include <iterator>
#include <string>
using namespace std;

/// Instead of the canonical form:
/// for (int i = 1; i < argc; ++i) {
///	cout << argv[i] << endl;
/// }

int main(int argc, char** argv)
{       // echo
	for_each(&argv[1], &argv[argc], // <- argv[1] to argv[argc-1]
		 [](char* s){cout << s << endl;});
	return 0;
}

// Local Variables:
// compile-command: "time -p LANG=C c++ -g -O3 -std=c++11 lambda-cout.cc -o echocc"
// End:
