/* Copyright (C) 2014 by Cesar A Quiroz, Ph.D.                     -*- C++ -*-
 * 3595 Granada Ave Unit 114 / Santa Clara, CA 95051 / USA
 * All Rights Reserved Worldwide
 * mailto:cesar.quiroz@gmail.com
 */

#ifndef VECTOR_AND_BUFFER_H
#define VECTOR_AND_BUFFER_H

#include <cstdlib>
#include <utility>
#include <vector>

using	Byte   = unsigned char;
using	Bytes  = std::vector<Byte>;

using	Buffer = std::pair<void*, size_t>;

inline Bytes Buffer_to_Bytes(Buffer const& buf)
{
	Byte*  bp = (Byte*)buf.first;
	size_t sz = buf.second;

	return Bytes{bp, bp+sz};
}

// ATTENTION: the Buffer is transient, shares data with the vector.
// If the vector is destructed, the Buffer is invalidated.
inline Buffer Bytes_to_Buffer(Bytes const& byt)
{
	return std::make_pair((void*)byt.data(), byt.size());
}

#endif /* VECTOR_AND_BUFFER_H */
/// end vector-and-buffer.h
