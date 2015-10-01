#include "vector_and_buffer.h"
#include <iostream>
#include <iterator>

using namespace std;

int main()
{
	Bytes vec { '0', '1', '2' };
	Buffer buf = Bytes_to_Buffer(vec);
	Bytes  ve2 = Buffer_to_Bytes(buf);


	cout << "vec data at " << (void*)vec.data() << endl;
	cout << "vec size " << vec.size() << endl;
	cout << "vec { ";
	copy(vec.begin(), vec.end(), ostream_iterator<Byte>(cout, " "));
	cout << " }\n";
	cout << "buf { " << (void*)buf.first << ", " << buf.second << " }\n";
	cout << "ve2 data at " << (void*)ve2.data() << endl;
	cout << "ve2 size " << ve2.size() << endl;
	cout << "ve2 { ";
	copy(vec.begin(), vec.end(), ostream_iterator<Byte>(cout, " "));
	cout << " }\n";
}

/// Local Variables:
/// compile-command: "time -p LANG=C c++ -o vnb vector_and_buffer.cpp -g3 -O0 -std=c++11"
/// End:
