#include <vector>
#include <deque>
#include <list>
#include <forward_list>

#include <stack>
#include <queue>

#include <map>
#include <set>

#include <unordered_map>
#include <unordered_set>

#include <string>
#include <utility>
#include <tuple>

#include <array>

#include <iostream>

#define OUT_CSIZE(d) cout << "sizeof(" #d << ") = " << sizeof(d) << endl;
// #define OUT_CSiZE(...) cout << "sizeof(" ##__VA_ARGS__ << ") = " << sizeof(__VA_ARGS__) << endl;
// #define OUT_CSiZE(...) cout <<  sizeof(__VA_ARGS__) << endl;

using namespace std;
using pair_sample = pair<unsigned long long, unsigned long long>;
using array0_sample = array<unsigned long long, 0>;
using array1_sample = array<unsigned long long, 0>;

int main()
{
	OUT_CSIZE(unsigned long long);
	OUT_CSIZE(vector<unsigned long long>);
	OUT_CSIZE(deque<unsigned long long>);
	OUT_CSIZE(list<unsigned long long>);
	OUT_CSIZE(forward_list<unsigned long long>);
	OUT_CSIZE(stack<unsigned long long>);
	OUT_CSIZE(queue<unsigned long long>);
	OUT_CSIZE(priority_queue<unsigned long long>);
	OUT_CSIZE(string);
	OUT_CSIZE(u32string);

	OUT_CSIZE(pair_sample);
	OUT_CSIZE(tuple<unsigned long long>);


	OUT_CSIZE(array0_sample);
	OUT_CSIZE(array1_sample);

	return 0;
}

// Local Variables:
// compile-command: "c++ -o containers-size -g -O0 -std=c++11 -Wall -Wextra -Werror containers-size.cc"
// End:
