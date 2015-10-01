#include <functional>

template<typename R1, typename A1, typename A2>
struct compos {
	std::function<R1(A1)> f1;
	std::function<A1(A2)> f2;

	compos(std::function<R1(A1)> f1, std::function<A1(A2)> f2): f1(f1), f2(f2) { };
	R1 operator()(A2 a2) { return f1(f2(a2)); };
};

int main()
{
	compos<double,double,int>
		c([] (double x) -> double { return 1/x; },
		  [] (int y)    -> double { return y*y; });

	return 100.0 * c(2); // exits 25
}

// Local Variables:
// compile-command: "c++ -o function function.cc -g3 -O0 -std=c++11 -Wall -Wextra -Werror"
// End:
