#include <chrono>
#include <iostream>
#include <inttypes.h>
#include <unistd.h>

using namespace std;

constexpr intmax_t min_res = 1000000;	// microsecond resolution.

template<typename C>
void count_beats(int seconds)
{
	typename C::time_point start = C::now();
	sleep(seconds);
	typename C::time_point end   = C::now();

	cout << "Measured "
	     << chrono::duration_cast<chrono::microseconds>(end - start)
		.count()
	     << " microseconds in " << seconds
	     << ((seconds != 1) ? string(" seconds") : string(" second")) << ".\n";
}

template<typename C>
void consider(string title, intmax_t resolution = min_res) 
{
	cout << title << ": start\n";
	cout << title << ": is "
	     << (C::is_steady ? "" : "not ") << "steady"
	     << ": has period ratio "
	     << typename C::period().num << " : "
	     << typename C::period().den;
		
	// num : den should be no worse than 1 : resolution
	// (which on current values is "at least microseconds")
	if ((resolution * typename C::period().num) <= (1 * typename C::period().den)) {
		cout << ": good enough for microseconds\n";
	} else {
		cout << ": not good enough for microseconds\n";
	}

	for (int i : {1, 5, 10}) {
		count_beats<C>(i);
	}

	cout << title << ": done\n";
}


int main(void)
{
	consider<chrono::system_clock>("System Clock", min_res);
	cout << endl;
	consider<chrono::steady_clock>("Steady Clock", min_res);
	cout << endl;
	consider<chrono::high_resolution_clock>("High Resolution Clock", min_res);

	return 0;
}

// Local Variables:
// compile-command: "c++ -g -O0 -std=c++11 -Wall -Wextra -Werror clocks.cc -o clocks"
// End:
