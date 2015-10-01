#include <algorithm>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

using namespace std;

inline bool starts_with(string word, string prefix)
{
	return word.compare(0, prefix.length(), prefix) == 0;
}

int main(int argc, char** argv)
{
	vector<string> probes {&argv[1], &argv[argc]};

	cout << "String probes: ";
	copy(probes.begin(), probes.end(), ostream_iterator<string>(cout, " "));
	cout << endl;

	for (string word; cin >> word;) {
		cout << "Probing \"" << word << "\"\n";
		for (auto const& probe : probes) {
			if (starts_with(word, probe)) {
				cout << " " << probe;
			}
		}
		cout << endl;
	}




	return 0;
}

#if 0
$ starts_with top.a.b top.a.b.xx top.a.c top.a.d top.a.d.a.d top.a.d.a.d.a.d
String probes: top.a.b top.a.b.xx top.a.c top.a.d top.a.d.a.d top.a.d.a.d.a.d
top.a.d.x
Probing "top.a.d.x"
 top.a.d
top.a.d.a.d.y
Probing "top.a.d.a.d.y"
 top.a.d top.a.d.a.d
top.a.d.a.d.a.d.z
Probing "top.a.d.a.d.a.d.z"
 top.a.d top.a.d.a.d top.a.d.a.d.a.d
top.a.d.a.d.a.d.a.d.a.d.t
Probing "top.a.d.a.d.a.d.a.d.a.d.t"
 top.a.d top.a.d.a.d top.a.d.a.d.a.d
x.y.z
Probing "x.y.z"

jfaskfj;ad
Probing "jfaskfj;ad"

$
#endif


// Local Variables:
// compile-command: "c++ -g -O0 -std=c++11 -Wall -Wextra -Werror -o starts_with starts_with.cc"
// End:
