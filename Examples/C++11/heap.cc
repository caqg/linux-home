#include <algorithm>
#include <iostream>
#include <iterator>
#include <utility>
#include <vector>

using namespace std;

int raw_powers[] = {
	0,				// ignored, it is 1-based
	23778751,
	29106573,
	84581385,
	15220829,
	58553734,
	19347538,
	81062270,
	17353068,
	48498321,
	15186262,
	36695705,
	49173647,
	91009411,
	26525690,
	89318755,
	22035095,
	63179837,
	57107715,
	33215757,
	10445476,
};


using Index = size_t;
using Power = unsigned long long;
using Entry = pair<size_t, Power>;
Index indexOf(Entry e) { return e.first; }
Power  powerOf(Entry e) { return e.second; }

vector<Power> powers(begin(raw_powers), end(raw_powers));
vector<Entry> expected {
	{ 13,  91009411 },
	{ 15, 89318755 },
	{ 3, 84581385 },
	{ 7, 81062270 },
	{ 17, 63179837 },
	{ 5, 58553734 },
	{ 18, 57107715 },
	{ 12, 49173647 },
	{ 9, 48498321 },
	{ 11, 36695705 }
}; 

// bool topN_cmp(Entry a, Entry b) { return a.second > b.second; };
static bool (*topN_cmp) (Entry a, Entry b)
	= [] (Entry a, Entry b) { return a.second > b.second; };

int main(void)
{
	vector<Entry> bpq;		// a min heap

	// 1-based
	for (size_t i = 1, in_q=0; i < powers.size(); ++i) {
		cout << "considering (" << i << ", " << powers[i] << ")\n";
		if (in_q < 10) {
			++in_q;
			// if not filled yet (in_q == 10),
			// enqueue (i, powers[i])
			bpq.push_back(make_pair(i, powers[i]));
			make_heap(bpq.begin(), bpq.end(), topN_cmp);
			cout << "enqueued (" << i << ", " << powers[i] << ")\n";
		} else {
			// If filled already, limit the enqueing to entries
			// that are not lesser than the minimum; newer entries
			// larger than the old minimum replace it (thereby
			// perhaps exposing another minimum).
			if (powers[i] > powerOf(bpq[0])) {
				cout << "replaced " << "(" << indexOf(bpq[0])
				     << ", " << powerOf(bpq[0]) << ") with (";
				bpq[0] = make_pair(i, powers[i]);
				cout << indexOf(bpq[0]) << ", " << powerOf(bpq[0])
				     << ")\n";
				make_heap(bpq.begin(), bpq.end(), topN_cmp);
			} else {
				cout << "no change\n";
			}
		}

		cout << "at end of iteration " << i << ", there are " << in_q
		     << " entries in the queue, new min of max is ("
		     << indexOf(bpq[0]) << ", " << powerOf(bpq[0])  << ")\n\n";
	}

	cout << "Done considering\n\n";

	cout << "Size of the queue should be 10 or less: It is "
	     << bpq.size()
	     << "\n\n";

	cout << "Final Heap, " << bpq.size() << " entries:\n";
	for (size_t i = 0; i < bpq.size(); ++i) {
		cout << indexOf(bpq[i]) << "\t" << powerOf(bpq[i]) << "\n";
	}

	sort_heap(bpq.begin(), bpq.end(), topN_cmp);

	cout << "\nTop 10 (or fewer)\n";
	int failures=0;
	for (size_t i = 0; i < bpq.size(); ++i) {
		cout << "OBSERVED\t" << indexOf(bpq[i]) << "\t"
		     << powerOf(bpq[i]) << "\n";
		cout << "EXPECTED\t" << indexOf(expected[i]) << "\t"
		     << powerOf(expected[i]) << "\n";
		bool did_it_pass = bpq[i] == expected[i];
		cout << (did_it_pass? "PASS" : "FAIL") << "\n\n";
		if (!did_it_pass) ++failures;
	}
	cout << failures << " failures.\n\n";

	vector<Index> whichOnes;
	
	transform(bpq.begin(), bpq.end(), back_inserter(whichOnes),
		  [] (Entry e) { return e.first; });
	cout << "Indices from the queue\n";
	copy(whichOnes.begin(), whichOnes.end(), ostream_iterator<Index>(cout, " "));
	cout << endl;
	
	return 0;
}

// Local Variables:
// compile-command: "g++ -g -O0 -std=c++11 -Wall -Wextra -Werror -o heap heap.cc"
// End:
