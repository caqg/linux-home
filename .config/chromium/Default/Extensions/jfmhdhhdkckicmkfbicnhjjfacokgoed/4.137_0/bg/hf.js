function runHF() {

    log("runHF called");

    /* ### pako 0.2.1, nodeca/pako license: https://www.versioneye.com/javascript/nodeca:pako/0.2.1 */
    !function (t) { if ("object" == typeof exports) module.exports = t(); else if ("function" == typeof define && define.amd) define(t); else { var e; "undefined" != typeof window ? e = window : "undefined" != typeof global ? e = global : "undefined" != typeof self && (e = self), e.pako = t() } }(function () { return function t(e, a, n) { function r(s, h) { if (!a[s]) { if (!e[s]) { var l = "function" == typeof require && require; if (!h && l) return l(s, !0); if (i) return i(s, !0); throw new Error("Cannot find module '" + s + "'") } var o = a[s] = { exports: {} }; e[s][0].call(o.exports, function (t) { var a = e[s][1][t]; return r(a ? a : t) }, o, o.exports, t, e, a, n) } return a[s].exports } for (var i = "function" == typeof require && require, s = 0; s < n.length; s++) r(n[s]); return r }({ 1: [function (t, e, a) { "use strict"; function n(t, e) { var a = new b(e); if (a.push(t, !0), a.err) throw a.msg; return a.result } function r(t, e) { return e = e || {}, e.raw = !0, n(t, e) } function i(t, e) { return e = e || {}, e.gzip = !0, n(t, e) } var s = t("./zlib/deflate.js"), h = t("./utils/common"), l = t("./utils/strings"), o = t("./zlib/messages"), _ = t("./zlib/zstream"), d = 0, u = 4, f = 0, c = 1, g = -1, p = 0, m = 8, b = function (t) { this.options = h.assign({ level: g, method: m, chunkSize: 16384, windowBits: 15, memLevel: 8, strategy: p, to: "" }, t || {}); var e = this.options; e.raw && e.windowBits > 0 ? e.windowBits = -e.windowBits : e.gzip && e.windowBits > 0 && e.windowBits < 16 && (e.windowBits += 16), this.err = 0, this.msg = "", this.ended = !1, this.chunks = [], this.strm = new _, this.strm.avail_out = 0; var a = s.deflateInit2(this.strm, e.level, e.method, e.windowBits, e.memLevel, e.strategy); if (a !== f) throw new Error(o[a]); e.header && s.deflateSetHeader(this.strm, e.header) }; b.prototype.push = function (t, e) { var a, n, r = this.strm, i = this.options.chunkSize; if (this.ended) return !1; n = e === ~~e ? e : e === !0 ? u : d, r.input = "string" == typeof t ? l.string2buf(t) : t, r.next_in = 0, r.avail_in = r.input.length; do { if (0 === r.avail_out && (r.output = new h.Buf8(i), r.next_out = 0, r.avail_out = i), a = s.deflate(r, n), a !== c && a !== f) return this.onEnd(a), this.ended = !0, !1; (0 === r.avail_out || 0 === r.avail_in && n === u) && this.onData("string" === this.options.to ? l.buf2binstring(h.shrinkBuf(r.output, r.next_out)) : h.shrinkBuf(r.output, r.next_out)) } while ((r.avail_in > 0 || 0 === r.avail_out) && a !== c); return n === u ? (a = s.deflateEnd(this.strm), this.onEnd(a), this.ended = !0, a === f) : !0 }, b.prototype.onData = function (t) { this.chunks.push(t) }, b.prototype.onEnd = function (t) { t === f && (this.result = "string" === this.options.to ? this.chunks.join("") : h.flattenChunks(this.chunks)), this.chunks = [], this.err = t, this.msg = this.strm.msg }, a.Deflate = b, a.deflate = n, a.deflateRaw = r, a.gzip = i }, { "./utils/common": 2, "./utils/strings": 3, "./zlib/deflate.js": 6, "./zlib/messages": 7, "./zlib/zstream": 9 }], 2: [function (t, e, a) { "use strict"; var n = "undefined" != typeof Uint8Array && "undefined" != typeof Uint16Array && "undefined" != typeof Int32Array; a.assign = function (t) { for (var e = Array.prototype.slice.call(arguments, 1) ; e.length;) { var a = e.shift(); if (a) { if ("object" != typeof a) throw new TypeError(a + "must be non-object"); for (var n in a) a.hasOwnProperty(n) && (t[n] = a[n]) } } return t }, a.shrinkBuf = function (t, e) { return t.length === e ? t : t.subarray ? t.subarray(0, e) : (t.length = e, t) }; var r = { arraySet: function (t, e, a, n, r) { if (e.subarray && t.subarray) return void t.set(e.subarray(a, a + n), r); for (var i = 0; n > i; i++) t[r + i] = e[a + i] }, flattenChunks: function (t) { var e, a, n, r, i, s; for (n = 0, e = 0, a = t.length; a > e; e++) n += t[e].length; for (s = new Uint8Array(n), r = 0, e = 0, a = t.length; a > e; e++) i = t[e], s.set(i, r), r += i.length; return s } }, i = { arraySet: function (t, e, a, n, r) { for (var i = 0; n > i; i++) t[r + i] = e[a + i] }, flattenChunks: function (t) { return [].concat.apply([], t) } }; a.setTyped = function (t) { t ? (a.Buf8 = Uint8Array, a.Buf16 = Uint16Array, a.Buf32 = Int32Array, a.assign(a, r)) : (a.Buf8 = Array, a.Buf16 = Array, a.Buf32 = Array, a.assign(a, i)) }, a.setTyped(n) }, {}], 3: [function (t, e, a) { "use strict"; var n = t("./common"), r = !0; try { String.fromCharCode.apply(null, [0]) } catch (i) { r = !1 } for (var s = new n.Buf8(256), h = 0; 256 > h; h++) s[h] = h >= 252 ? 6 : h >= 248 ? 5 : h >= 240 ? 4 : h >= 224 ? 3 : h >= 192 ? 2 : 1; s[254] = s[254] = 1, a.string2buf = function (t) { var e, a, r, i, s, h = t.length, l = 0; for (i = 0; h > i; i++) a = t.charCodeAt(i), 55296 === (64512 & a) && h > i + 1 && (r = t.charCodeAt(i + 1), 56320 === (64512 & r) && (a = 65536 + (a - 55296 << 10) + (r - 56320), i++)), l += 128 > a ? 1 : 2048 > a ? 2 : 65536 > a ? 3 : 4; for (e = new n.Buf8(l), s = 0, i = 0; l > s; i++) a = t.charCodeAt(i), 55296 === (64512 & a) && h > i + 1 && (r = t.charCodeAt(i + 1), 56320 === (64512 & r) && (a = 65536 + (a - 55296 << 10) + (r - 56320), i++)), 128 > a ? e[s++] = a : 2048 > a ? (e[s++] = 192 | a >>> 6, e[s++] = 128 | 63 & a) : 65536 > a ? (e[s++] = 224 | a >>> 12, e[s++] = 128 | a >>> 6 & 63, e[s++] = 128 | 63 & a) : (e[s++] = 240 | a >>> 18, e[s++] = 128 | a >>> 12 & 63, e[s++] = 128 | a >>> 6 & 63, e[s++] = 128 | 63 & a); return e }, a.buf2binstring = function (t) { if (r && t.length < 65537) return String.fromCharCode.apply(null, t); for (var e = "", a = 0, n = t.length; n > a; a++) e += String.fromCharCode(t[a]); return e }, a.binstring2buf = function (t) { for (var e = new n.Buf8(t.length), a = 0, r = e.length; r > a; a++) e[a] = t.charCodeAt(a); return e }, a.buf2string = function (t, e) { var a, i, h, l, o, _ = e || t.length, d = new Array(2 * _); for (h = 0, i = 0; _ > i;) if (l = t[i++], 128 > l) d[h++] = l; else if (o = s[l], o > 4) d[h++] = 65533, i += o - 1; else { for (l &= 2 === o ? 31 : 3 === o ? 15 : 7; o > 1 && _ > i;) l = l << 6 | 63 & t[i++], o--; o > 1 ? d[h++] = 65533 : 65536 > l ? d[h++] = l : (l -= 65536, d[h++] = 55296 | l >> 10 & 1023, d[h++] = 56320 | 1023 & l) } if (r) return String.fromCharCode.apply(null, n.shrinkBuf(d, h)); for (a = "", i = 0, _ = h; _ > i; i++) a += String.fromCharCode(d[i]); return a }, a.utf8border = function (t, e) { var a; for (e = e || t.length, e > t.length && (e = t.length), a = e - 1; a >= 0 && 128 === (192 & t[a]) ;) a--; return 0 > a ? e : 0 === a ? e : a + s[t[a]] > e ? a : e } }, { "./common": 2 }], 4: [function (t, e) { "use strict"; function a(t, e, a, n) { for (var r = 65535 & t | 0, i = t >>> 16 & 65535 | 0, s = 0; 0 !== a;) { s = a > 2e3 ? 2e3 : a, a -= s; do r = r + e[n++] | 0, i = i + r | 0; while (--s); r %= 65521, i %= 65521 } return r | i << 16 | 0 } e.exports = a }, {}], 5: [function (t, e) { "use strict"; function a() { for (var t, e = [], a = 0; 256 > a; a++) { t = a; for (var n = 0; 8 > n; n++) t = 1 & t ? 3988292384 ^ t >>> 1 : t >>> 1; e[a] = t } return e } function n(t, e, a, n) { var i = r, s = n + a; t = -1 ^ t; for (var h = n; s > h; h++) t = t >>> 8 ^ i[255 & (t ^ e[h])]; return -1 ^ t } var r = a(); e.exports = n }, {}], 6: [function (t, e, a) { "use strict"; function n(t, e) { return t.msg = U[e], e } function r(t) { return (t << 1) - (t > 4 ? 9 : 0) } function i(t) { for (var e = t.length; --e >= 0;) t[e] = 0 } function s(t) { var e = t.state, a = e.pending; a > t.avail_out && (a = t.avail_out), 0 !== a && (S.arraySet(t.output, e.pending_buf, e.pending_out, a, t.next_out), t.next_out += a, e.pending_out += a, t.total_out += a, t.avail_out -= a, e.pending -= a, 0 === e.pending && (e.pending_out = 0)) } function h(t, e) { E._tr_flush_block(t, t.block_start >= 0 ? t.block_start : -1, t.strstart - t.block_start, e), t.block_start = t.strstart, s(t.strm) } function l(t, e) { t.pending_buf[t.pending++] = e } function o(t, e) { t.pending_buf[t.pending++] = e >>> 8 & 255, t.pending_buf[t.pending++] = 255 & e } function _(t, e, a, n) { var r = t.avail_in; return r > n && (r = n), 0 === r ? 0 : (t.avail_in -= r, S.arraySet(e, t.input, t.next_in, r, a), 1 === t.state.wrap ? t.adler = j(t.adler, e, r, a) : 2 === t.state.wrap && (t.adler = I(t.adler, e, r, a)), t.next_in += r, t.total_in += r, r) } function d(t, e) { var a, n, r = t.max_chain_length, i = t.strstart, s = t.prev_length, h = t.nice_match, l = t.strstart > t.w_size - oe ? t.strstart - (t.w_size - oe) : 0, o = t.window, _ = t.w_mask, d = t.prev, u = t.strstart + le, f = o[i + s - 1], c = o[i + s]; t.prev_length >= t.good_match && (r >>= 2), h > t.lookahead && (h = t.lookahead); do if (a = e, o[a + s] === c && o[a + s - 1] === f && o[a] === o[i] && o[++a] === o[i + 1]) { i += 2, a++; do; while (o[++i] === o[++a] && o[++i] === o[++a] && o[++i] === o[++a] && o[++i] === o[++a] && o[++i] === o[++a] && o[++i] === o[++a] && o[++i] === o[++a] && o[++i] === o[++a] && u > i); if (n = le - (u - i), i = u - le, n > s) { if (t.match_start = e, s = n, n >= h) break; f = o[i + s - 1], c = o[i + s] } } while ((e = d[e & _]) > l && 0 !== --r); return s <= t.lookahead ? s : t.lookahead } function u(t) { var e, a, n, r, i, s = t.w_size; do { if (r = t.window_size - t.lookahead - t.strstart, t.strstart >= s + (s - oe)) { S.arraySet(t.window, t.window, s, s, 0), t.match_start -= s, t.strstart -= s, t.block_start -= s, a = t.hash_size, e = a; do n = t.head[--e], t.head[e] = n >= s ? n - s : 0; while (--a); a = s, e = a; do n = t.prev[--e], t.prev[e] = n >= s ? n - s : 0; while (--a); r += s } if (0 === t.strm.avail_in) break; if (a = _(t.strm, t.window, t.strstart + t.lookahead, r), t.lookahead += a, t.lookahead + t.insert >= he) for (i = t.strstart - t.insert, t.ins_h = t.window[i], t.ins_h = (t.ins_h << t.hash_shift ^ t.window[i + 1]) & t.hash_mask; t.insert && (t.ins_h = (t.ins_h << t.hash_shift ^ t.window[i + he - 1]) & t.hash_mask, t.prev[i & t.w_mask] = t.head[t.ins_h], t.head[t.ins_h] = i, i++, t.insert--, !(t.lookahead + t.insert < he)) ;); } while (t.lookahead < oe && 0 !== t.strm.avail_in) } function f(t, e) { var a = 65535; for (a > t.pending_buf_size - 5 && (a = t.pending_buf_size - 5) ; ;) { if (t.lookahead <= 1) { if (u(t), 0 === t.lookahead && e === q) return be; if (0 === t.lookahead) break } t.strstart += t.lookahead, t.lookahead = 0; var n = t.block_start + a; if ((0 === t.strstart || t.strstart >= n) && (t.lookahead = t.strstart - n, t.strstart = n, h(t, !1), 0 === t.strm.avail_out)) return be; if (t.strstart - t.block_start >= t.w_size - oe && (h(t, !1), 0 === t.strm.avail_out)) return be } return t.insert = 0, e === T ? (h(t, !0), 0 === t.strm.avail_out ? we : ye) : t.strstart > t.block_start && (h(t, !1), 0 === t.strm.avail_out) ? be : be } function c(t, e) { for (var a, n; ;) { if (t.lookahead < oe) { if (u(t), t.lookahead < oe && e === q) return be; if (0 === t.lookahead) break } if (a = 0, t.lookahead >= he && (t.ins_h = (t.ins_h << t.hash_shift ^ t.window[t.strstart + he - 1]) & t.hash_mask, a = t.prev[t.strstart & t.w_mask] = t.head[t.ins_h], t.head[t.ins_h] = t.strstart), 0 !== a && t.strstart - a <= t.w_size - oe && (t.match_length = d(t, a)), t.match_length >= he) if (n = E._tr_tally(t, t.strstart - t.match_start, t.match_length - he), t.lookahead -= t.match_length, t.match_length <= t.max_lazy_match && t.lookahead >= he) { t.match_length--; do t.strstart++, t.ins_h = (t.ins_h << t.hash_shift ^ t.window[t.strstart + he - 1]) & t.hash_mask, a = t.prev[t.strstart & t.w_mask] = t.head[t.ins_h], t.head[t.ins_h] = t.strstart; while (0 !== --t.match_length); t.strstart++ } else t.strstart += t.match_length, t.match_length = 0, t.ins_h = t.window[t.strstart], t.ins_h = (t.ins_h << t.hash_shift ^ t.window[t.strstart + 1]) & t.hash_mask; else n = E._tr_tally(t, 0, t.window[t.strstart]), t.lookahead--, t.strstart++; if (n && (h(t, !1), 0 === t.strm.avail_out)) return be } return t.insert = t.strstart < he - 1 ? t.strstart : he - 1, e === T ? (h(t, !0), 0 === t.strm.avail_out ? we : ye) : t.last_lit && (h(t, !1), 0 === t.strm.avail_out) ? be : ve } function g(t, e) { for (var a, n, r; ;) { if (t.lookahead < oe) { if (u(t), t.lookahead < oe && e === q) return be; if (0 === t.lookahead) break } if (a = 0, t.lookahead >= he && (t.ins_h = (t.ins_h << t.hash_shift ^ t.window[t.strstart + he - 1]) & t.hash_mask, a = t.prev[t.strstart & t.w_mask] = t.head[t.ins_h], t.head[t.ins_h] = t.strstart), t.prev_length = t.match_length, t.prev_match = t.match_start, t.match_length = he - 1, 0 !== a && t.prev_length < t.max_lazy_match && t.strstart - a <= t.w_size - oe && (t.match_length = d(t, a), t.match_length <= 5 && (t.strategy === G || t.match_length === he && t.strstart - t.match_start > 4096) && (t.match_length = he - 1)), t.prev_length >= he && t.match_length <= t.prev_length) { r = t.strstart + t.lookahead - he, n = E._tr_tally(t, t.strstart - 1 - t.prev_match, t.prev_length - he), t.lookahead -= t.prev_length - 1, t.prev_length -= 2; do ++t.strstart <= r && (t.ins_h = (t.ins_h << t.hash_shift ^ t.window[t.strstart + he - 1]) & t.hash_mask, a = t.prev[t.strstart & t.w_mask] = t.head[t.ins_h], t.head[t.ins_h] = t.strstart); while (0 !== --t.prev_length); if (t.match_available = 0, t.match_length = he - 1, t.strstart++, n && (h(t, !1), 0 === t.strm.avail_out)) return be } else if (t.match_available) { if (n = E._tr_tally(t, 0, t.window[t.strstart - 1]), n && h(t, !1), t.strstart++, t.lookahead--, 0 === t.strm.avail_out) return be } else t.match_available = 1, t.strstart++, t.lookahead-- } return t.match_available && (n = E._tr_tally(t, 0, t.window[t.strstart - 1]), t.match_available = 0), t.insert = t.strstart < he - 1 ? t.strstart : he - 1, e === T ? (h(t, !0), 0 === t.strm.avail_out ? we : ye) : t.last_lit && (h(t, !1), 0 === t.strm.avail_out) ? be : ve } function p(t, e) { for (var a, n, r, i, s = t.window; ;) { if (t.lookahead <= le) { if (u(t), t.lookahead <= le && e === q) return be; if (0 === t.lookahead) break } if (t.match_length = 0, t.lookahead >= he && t.strstart > 0 && (r = t.strstart - 1, n = s[r], n === s[++r] && n === s[++r] && n === s[++r])) { i = t.strstart + le; do; while (n === s[++r] && n === s[++r] && n === s[++r] && n === s[++r] && n === s[++r] && n === s[++r] && n === s[++r] && n === s[++r] && i > r); t.match_length = le - (i - r), t.match_length > t.lookahead && (t.match_length = t.lookahead) } if (t.match_length >= he ? (a = E._tr_tally(t, 1, t.match_length - he), t.lookahead -= t.match_length, t.strstart += t.match_length, t.match_length = 0) : (a = E._tr_tally(t, 0, t.window[t.strstart]), t.lookahead--, t.strstart++), a && (h(t, !1), 0 === t.strm.avail_out)) return be } return t.insert = 0, e === T ? (h(t, !0), 0 === t.strm.avail_out ? we : ye) : t.last_lit && (h(t, !1), 0 === t.strm.avail_out) ? be : ve } function m(t, e) { for (var a; ;) { if (0 === t.lookahead && (u(t), 0 === t.lookahead)) { if (e === q) return be; break } if (t.match_length = 0, a = E._tr_tally(t, 0, t.window[t.strstart]), t.lookahead--, t.strstart++, a && (h(t, !1), 0 === t.strm.avail_out)) return be } return t.insert = 0, e === T ? (h(t, !0), 0 === t.strm.avail_out ? we : ye) : t.last_lit && (h(t, !1), 0 === t.strm.avail_out) ? be : ve } function b(t) { t.window_size = 2 * t.w_size, i(t.head), t.max_lazy_match = C[t.level].max_lazy, t.good_match = C[t.level].good_length, t.nice_match = C[t.level].nice_length, t.max_chain_length = C[t.level].max_chain, t.strstart = 0, t.block_start = 0, t.lookahead = 0, t.insert = 0, t.match_length = t.prev_length = he - 1, t.match_available = 0, t.ins_h = 0 } function v() { this.strm = null, this.status = 0, this.pending_buf = null, this.pending_buf_size = 0, this.pending_out = 0, this.pending = 0, this.wrap = 0, this.gzhead = null, this.gzindex = 0, this.method = X, this.last_flush = -1, this.w_size = 0, this.w_bits = 0, this.w_mask = 0, this.window = null, this.window_size = 0, this.prev = null, this.head = null, this.ins_h = 0, this.hash_size = 0, this.hash_bits = 0, this.hash_mask = 0, this.hash_shift = 0, this.block_start = 0, this.match_length = 0, this.prev_match = 0, this.match_available = 0, this.strstart = 0, this.match_start = 0, this.lookahead = 0, this.prev_length = 0, this.max_chain_length = 0, this.max_lazy_match = 0, this.level = 0, this.strategy = 0, this.good_match = 0, this.nice_match = 0, this.dyn_ltree = new S.Buf16(2 * ie), this.dyn_dtree = new S.Buf16(2 * (2 * ne + 1)), this.bl_tree = new S.Buf16(2 * (2 * re + 1)), i(this.dyn_ltree), i(this.dyn_dtree), i(this.bl_tree), this.l_desc = null, this.d_desc = null, this.bl_desc = null, this.bl_count = new S.Buf16(se + 1), this.heap = new S.Buf16(2 * ae + 1), i(this.heap), this.heap_len = 0, this.heap_max = 0, this.depth = new S.Buf16(2 * ae + 1), i(this.depth), this.l_buf = 0, this.lit_bufsize = 0, this.last_lit = 0, this.d_buf = 0, this.opt_len = 0, this.static_len = 0, this.matches = 0, this.insert = 0, this.bi_buf = 0, this.bi_valid = 0 } function w(t) { var e; return t && t.state ? (t.total_in = t.total_out = 0, t.data_type = W, e = t.state, e.pending = 0, e.pending_out = 0, e.wrap < 0 && (e.wrap = -e.wrap), e.status = e.wrap ? de : pe, t.adler = 2 === e.wrap ? 0 : 1, e.last_flush = q, E._tr_init(e), L) : n(t, N) } function y(t) { var e = w(t); return e === L && b(t.state), e } function z(t, e) { return t && t.state ? 2 !== t.state.wrap ? N : (t.state.gzhead = e, L) : N } function k(t, e, a, r, i, s) { if (!t) return N; var h = 1; if (e === F && (e = 6), 0 > r ? (h = 0, r = -r) : r > 15 && (h = 2, r -= 16), 1 > i || i > Y || a !== X || 8 > r || r > 15 || 0 > e || e > 9 || 0 > s || s > Q) return n(t, N); 8 === r && (r = 9); var l = new v; return t.state = l, l.strm = t, l.wrap = h, l.gzhead = null, l.w_bits = r, l.w_size = 1 << l.w_bits, l.w_mask = l.w_size - 1, l.hash_bits = i + 7, l.hash_size = 1 << l.hash_bits, l.hash_mask = l.hash_size - 1, l.hash_shift = ~~((l.hash_bits + he - 1) / he), l.window = new S.Buf8(2 * l.w_size), l.head = new S.Buf16(l.hash_size), l.prev = new S.Buf16(l.w_size), l.lit_bufsize = 1 << i + 6, l.pending_buf_size = 4 * l.lit_bufsize, l.pending_buf = new S.Buf8(l.pending_buf_size), l.d_buf = l.lit_bufsize >> 1, l.l_buf = 3 * l.lit_bufsize, l.level = e, l.strategy = s, l.method = a, y(t) } function x(t, e) { return k(t, e, X, Z, $, V) } function B(t, e) { var a, h, _, d; if (!t || !t.state || e > H || 0 > e) return t ? n(t, N) : N; if (h = t.state, !t.output || !t.input && 0 !== t.avail_in || h.status === me && e !== T) return n(t, 0 === t.avail_out ? P : N); if (h.strm = t, a = h.last_flush, h.last_flush = e, h.status === de) if (2 === h.wrap) t.adler = 0, l(h, 31), l(h, 139), l(h, 8), h.gzhead ? (l(h, (h.gzhead.text ? 1 : 0) + (h.gzhead.hcrc ? 2 : 0) + (h.gzhead.extra ? 4 : 0) + (h.gzhead.name ? 8 : 0) + (h.gzhead.comment ? 16 : 0)), l(h, 255 & h.gzhead.time), l(h, h.gzhead.time >> 8 & 255), l(h, h.gzhead.time >> 16 & 255), l(h, h.gzhead.time >> 24 & 255), l(h, 9 === h.level ? 2 : h.strategy >= J || h.level < 2 ? 4 : 0), l(h, 255 & h.gzhead.os), h.gzhead.extra && h.gzhead.extra.length && (l(h, 255 & h.gzhead.extra.length), l(h, h.gzhead.extra.length >> 8 & 255)), h.gzhead.hcrc && (t.adler = I(t.adler, h.pending_buf, h.pending, 0)), h.gzindex = 0, h.status = ue) : (l(h, 0), l(h, 0), l(h, 0), l(h, 0), l(h, 0), l(h, 9 === h.level ? 2 : h.strategy >= J || h.level < 2 ? 4 : 0), l(h, ze), h.status = pe); else { var u = X + (h.w_bits - 8 << 4) << 8, f = -1; f = h.strategy >= J || h.level < 2 ? 0 : h.level < 6 ? 1 : 6 === h.level ? 2 : 3, u |= f << 6, 0 !== h.strstart && (u |= _e), u += 31 - u % 31, h.status = pe, o(h, u), 0 !== h.strstart && (o(h, t.adler >>> 16), o(h, 65535 & t.adler)), t.adler = 1 } if (h.status === ue) if (h.gzhead.extra) { for (_ = h.pending; h.gzindex < (65535 & h.gzhead.extra.length) && (h.pending !== h.pending_buf_size || (h.gzhead.hcrc && h.pending > _ && (t.adler = I(t.adler, h.pending_buf, h.pending - _, _)), s(t), _ = h.pending, h.pending !== h.pending_buf_size)) ;) l(h, 255 & h.gzhead.extra[h.gzindex]), h.gzindex++; h.gzhead.hcrc && h.pending > _ && (t.adler = I(t.adler, h.pending_buf, h.pending - _, _)), h.gzindex === h.gzhead.extra.length && (h.gzindex = 0, h.status = fe) } else h.status = fe; if (h.status === fe) if (h.gzhead.name) { _ = h.pending; do { if (h.pending === h.pending_buf_size && (h.gzhead.hcrc && h.pending > _ && (t.adler = I(t.adler, h.pending_buf, h.pending - _, _)), s(t), _ = h.pending, h.pending === h.pending_buf_size)) { d = 1; break } d = h.gzindex < h.gzhead.name.length ? 255 & h.gzhead.name.charCodeAt(h.gzindex++) : 0, l(h, d) } while (0 !== d); h.gzhead.hcrc && h.pending > _ && (t.adler = I(t.adler, h.pending_buf, h.pending - _, _)), 0 === d && (h.gzindex = 0, h.status = ce) } else h.status = ce; if (h.status === ce) if (h.gzhead.comment) { _ = h.pending; do { if (h.pending === h.pending_buf_size && (h.gzhead.hcrc && h.pending > _ && (t.adler = I(t.adler, h.pending_buf, h.pending - _, _)), s(t), _ = h.pending, h.pending === h.pending_buf_size)) { d = 1; break } d = h.gzindex < h.gzhead.comment.length ? 255 & h.gzhead.comment.charCodeAt(h.gzindex++) : 0, l(h, d) } while (0 !== d); h.gzhead.hcrc && h.pending > _ && (t.adler = I(t.adler, h.pending_buf, h.pending - _, _)), 0 === d && (h.status = ge) } else h.status = ge; if (h.status === ge && (h.gzhead.hcrc ? (h.pending + 2 > h.pending_buf_size && s(t), h.pending + 2 <= h.pending_buf_size && (l(h, 255 & t.adler), l(h, t.adler >> 8 & 255), t.adler = 0, h.status = pe)) : h.status = pe), 0 !== h.pending) { if (s(t), 0 === t.avail_out) return h.last_flush = -1, L } else if (0 === t.avail_in && r(e) <= r(a) && e !== T) return n(t, P); if (h.status === me && 0 !== t.avail_in) return n(t, P); if (0 !== t.avail_in || 0 !== h.lookahead || e !== q && h.status !== me) { var c = h.strategy === J ? m(h, e) : h.strategy === M ? p(h, e) : C[h.level].func(h, e); if ((c === we || c === ye) && (h.status = me), c === be || c === we) return 0 === t.avail_out && (h.last_flush = -1), L; if (c === ve && (e === D ? E._tr_align(h) : e !== H && (E._tr_stored_block(h, 0, 0, !1), e === R && (i(h.head), 0 === h.lookahead && (h.strstart = 0, h.block_start = 0, h.insert = 0))), s(t), 0 === t.avail_out)) return h.last_flush = -1, L } return e !== T ? L : h.wrap <= 0 ? K : (2 === h.wrap ? (l(h, 255 & t.adler), l(h, t.adler >> 8 & 255), l(h, t.adler >> 16 & 255), l(h, t.adler >> 24 & 255), l(h, 255 & t.total_in), l(h, t.total_in >> 8 & 255), l(h, t.total_in >> 16 & 255), l(h, t.total_in >> 24 & 255)) : (o(h, t.adler >>> 16), o(h, 65535 & t.adler)), s(t), h.wrap > 0 && (h.wrap = -h.wrap), 0 !== h.pending ? L : K) } function A(t) { var e; return t && t.state ? (e = t.state.status, e !== de && e !== ue && e !== fe && e !== ce && e !== ge && e !== pe && e !== me ? n(t, N) : (t.state = null, e === pe ? n(t, O) : L)) : N } var C, S = t("../utils/common"), E = t("./trees"), j = t("./adler32"), I = t("./crc32"), U = t("./messages"), q = 0, D = 1, R = 3, T = 4, H = 5, L = 0, K = 1, N = -2, O = -3, P = -5, F = -1, G = 1, J = 2, M = 3, Q = 4, V = 0, W = 2, X = 8, Y = 9, Z = 15, $ = 8, te = 29, ee = 256, ae = ee + 1 + te, ne = 30, re = 19, ie = 2 * ae + 1, se = 15, he = 3, le = 258, oe = le + he + 1, _e = 32, de = 42, ue = 69, fe = 73, ce = 91, ge = 103, pe = 113, me = 666, be = 1, ve = 2, we = 3, ye = 4, ze = 3, ke = function (t, e, a, n, r) { this.good_length = t, this.max_lazy = e, this.nice_length = a, this.max_chain = n, this.func = r }; C = [new ke(0, 0, 0, 0, f), new ke(4, 4, 8, 4, c), new ke(4, 5, 16, 8, c), new ke(4, 6, 32, 32, c), new ke(4, 4, 16, 16, g), new ke(8, 16, 32, 32, g), new ke(8, 16, 128, 128, g), new ke(8, 32, 128, 256, g), new ke(32, 128, 258, 1024, g), new ke(32, 258, 258, 4096, g)], a.deflateInit = x, a.deflateInit2 = k, a.deflateReset = y, a.deflateResetKeep = w, a.deflateSetHeader = z, a.deflate = B, a.deflateEnd = A, a.deflateInfo = "pako deflate (from Nodeca project)" }, { "../utils/common": 2, "./adler32": 4, "./crc32": 5, "./messages": 7, "./trees": 8 }], 7: [function (t, e) { "use strict"; e.exports = { 2: "need dictionary", 1: "stream end", 0: "", "-1": "file error", "-2": "stream error", "-3": "data error", "-4": "insufficient memory", "-5": "buffer error", "-6": "incompatible version" } }, {}], 8: [function (t, e, a) { "use strict"; function n(t) { for (var e = t.length; --e >= 0;) t[e] = 0 } function r(t) { return 256 > t ? se[t] : se[256 + (t >>> 7)] } function i(t, e) { t.pending_buf[t.pending++] = 255 & e, t.pending_buf[t.pending++] = e >>> 8 & 255 } function s(t, e, a) { t.bi_valid > Q - a ? (t.bi_buf |= e << t.bi_valid & 65535, i(t, t.bi_buf), t.bi_buf = e >> Q - t.bi_valid, t.bi_valid += a - Q) : (t.bi_buf |= e << t.bi_valid & 65535, t.bi_valid += a) } function h(t, e, a) { s(t, a[2 * e], a[2 * e + 1]) } function l(t, e) { var a = 0; do a |= 1 & t, t >>>= 1, a <<= 1; while (--e > 0); return a >>> 1 } function o(t) { 16 === t.bi_valid ? (i(t, t.bi_buf), t.bi_buf = 0, t.bi_valid = 0) : t.bi_valid >= 8 && (t.pending_buf[t.pending++] = 255 & t.bi_buf, t.bi_buf >>= 8, t.bi_valid -= 8) } function _(t, e) { var a, n, r, i, s, h, l = e.dyn_tree, o = e.max_code, _ = e.stat_desc.static_tree, d = e.stat_desc.has_stree, u = e.stat_desc.extra_bits, f = e.stat_desc.extra_base, c = e.stat_desc.max_length, g = 0; for (i = 0; M >= i; i++) t.bl_count[i] = 0; for (l[2 * t.heap[t.heap_max] + 1] = 0, a = t.heap_max + 1; J > a; a++) n = t.heap[a], i = l[2 * l[2 * n + 1] + 1] + 1, i > c && (i = c, g++), l[2 * n + 1] = i, n > o || (t.bl_count[i]++, s = 0, n >= f && (s = u[n - f]), h = l[2 * n], t.opt_len += h * (i + s), d && (t.static_len += h * (_[2 * n + 1] + s))); if (0 !== g) { do { for (i = c - 1; 0 === t.bl_count[i];) i--; t.bl_count[i]--, t.bl_count[i + 1] += 2, t.bl_count[c]--, g -= 2 } while (g > 0); for (i = c; 0 !== i; i--) for (n = t.bl_count[i]; 0 !== n;) r = t.heap[--a], r > o || (l[2 * r + 1] !== i && (t.opt_len += (i - l[2 * r + 1]) * l[2 * r], l[2 * r + 1] = i), n--) } } function d(t, e, a) { var n, r, i = new Array(M + 1), s = 0; for (n = 1; M >= n; n++) i[n] = s = s + a[n - 1] << 1; for (r = 0; e >= r; r++) { var h = t[2 * r + 1]; 0 !== h && (t[2 * r] = l(i[h]++, h)) } } function u() { var t, e, a, n, r, i = new Array(M + 1); for (a = 0, n = 0; N - 1 > n; n++) for (le[n] = a, t = 0; t < 1 << $[n]; t++) he[a++] = n; for (he[a - 1] = n, r = 0, n = 0; 16 > n; n++) for (oe[n] = r, t = 0; t < 1 << te[n]; t++) se[r++] = n; for (r >>= 7; F > n; n++) for (oe[n] = r << 7, t = 0; t < 1 << te[n] - 7; t++) se[256 + r++] = n; for (e = 0; M >= e; e++) i[e] = 0; for (t = 0; 143 >= t;) re[2 * t + 1] = 8, t++, i[8]++; for (; 255 >= t;) re[2 * t + 1] = 9, t++, i[9]++; for (; 279 >= t;) re[2 * t + 1] = 7, t++, i[7]++; for (; 287 >= t;) re[2 * t + 1] = 8, t++, i[8]++; for (d(re, P + 1, i), t = 0; F > t; t++) ie[2 * t + 1] = 5, ie[2 * t] = l(t, 5); _e = new fe(re, $, O + 1, P, M), de = new fe(ie, te, 0, F, M), ue = new fe(new Array(0), ee, 0, G, V) } function f(t) { var e; for (e = 0; P > e; e++) t.dyn_ltree[2 * e] = 0; for (e = 0; F > e; e++) t.dyn_dtree[2 * e] = 0; for (e = 0; G > e; e++) t.bl_tree[2 * e] = 0; t.dyn_ltree[2 * W] = 1, t.opt_len = t.static_len = 0, t.last_lit = t.matches = 0 } function c(t) { t.bi_valid > 8 ? i(t, t.bi_buf) : t.bi_valid > 0 && (t.pending_buf[t.pending++] = t.bi_buf), t.bi_buf = 0, t.bi_valid = 0 } function g(t, e, a, n) { c(t), n && (i(t, a), i(t, ~a)), j.arraySet(t.pending_buf, t.window, e, a, t.pending), t.pending += a } function p(t, e, a, n) { var r = 2 * e, i = 2 * a; return t[r] < t[i] || t[r] === t[i] && n[e] <= n[a] } function m(t, e, a) { for (var n = t.heap[a], r = a << 1; r <= t.heap_len && (r < t.heap_len && p(e, t.heap[r + 1], t.heap[r], t.depth) && r++, !p(e, n, t.heap[r], t.depth)) ;) t.heap[a] = t.heap[r], a = r, r <<= 1; t.heap[a] = n } function b(t, e, a) { var n, i, l, o, _ = 0; if (0 !== t.last_lit) do n = t.pending_buf[t.d_buf + 2 * _] << 8 | t.pending_buf[t.d_buf + 2 * _ + 1], i = t.pending_buf[t.l_buf + _], _++, 0 === n ? h(t, i, e) : (l = he[i], h(t, l + O + 1, e), o = $[l], 0 !== o && (i -= le[l], s(t, i, o)), n--, l = r(n), h(t, l, a), o = te[l], 0 !== o && (n -= oe[l], s(t, n, o))); while (_ < t.last_lit); h(t, W, e) } function v(t, e) { var a, n, r, i = e.dyn_tree, s = e.stat_desc.static_tree, h = e.stat_desc.has_stree, l = e.stat_desc.elems, o = -1; for (t.heap_len = 0, t.heap_max = J, a = 0; l > a; a++) 0 !== i[2 * a] ? (t.heap[++t.heap_len] = o = a, t.depth[a] = 0) : i[2 * a + 1] = 0; for (; t.heap_len < 2;) r = t.heap[++t.heap_len] = 2 > o ? ++o : 0, i[2 * r] = 1, t.depth[r] = 0, t.opt_len--, h && (t.static_len -= s[2 * r + 1]); for (e.max_code = o, a = t.heap_len >> 1; a >= 1; a--) m(t, i, a); r = l; do a = t.heap[1], t.heap[1] = t.heap[t.heap_len--], m(t, i, 1), n = t.heap[1], t.heap[--t.heap_max] = a, t.heap[--t.heap_max] = n, i[2 * r] = i[2 * a] + i[2 * n], t.depth[r] = (t.depth[a] >= t.depth[n] ? t.depth[a] : t.depth[n]) + 1, i[2 * a + 1] = i[2 * n + 1] = r, t.heap[1] = r++, m(t, i, 1); while (t.heap_len >= 2); t.heap[--t.heap_max] = t.heap[1], _(t, e), d(i, o, t.bl_count) } function w(t, e, a) { var n, r, i = -1, s = e[1], h = 0, l = 7, o = 4; for (0 === s && (l = 138, o = 3), e[2 * (a + 1) + 1] = 65535, n = 0; a >= n; n++) r = s, s = e[2 * (n + 1) + 1], ++h < l && r === s || (o > h ? t.bl_tree[2 * r] += h : 0 !== r ? (r !== i && t.bl_tree[2 * r]++, t.bl_tree[2 * X]++) : 10 >= h ? t.bl_tree[2 * Y]++ : t.bl_tree[2 * Z]++, h = 0, i = r, 0 === s ? (l = 138, o = 3) : r === s ? (l = 6, o = 3) : (l = 7, o = 4)) } function y(t, e, a) { var n, r, i = -1, l = e[1], o = 0, _ = 7, d = 4; for (0 === l && (_ = 138, d = 3), n = 0; a >= n; n++) if (r = l, l = e[2 * (n + 1) + 1], !(++o < _ && r === l)) { if (d > o) { do h(t, r, t.bl_tree); while (0 !== --o) } else 0 !== r ? (r !== i && (h(t, r, t.bl_tree), o--), h(t, X, t.bl_tree), s(t, o - 3, 2)) : 10 >= o ? (h(t, Y, t.bl_tree), s(t, o - 3, 3)) : (h(t, Z, t.bl_tree), s(t, o - 11, 7)); o = 0, i = r, 0 === l ? (_ = 138, d = 3) : r === l ? (_ = 6, d = 3) : (_ = 7, d = 4) } } function z(t) { var e; for (w(t, t.dyn_ltree, t.l_desc.max_code), w(t, t.dyn_dtree, t.d_desc.max_code), v(t, t.bl_desc), e = G - 1; e >= 3 && 0 === t.bl_tree[2 * ae[e] + 1]; e--); return t.opt_len += 3 * (e + 1) + 5 + 5 + 4, e } function k(t, e, a, n) { var r; for (s(t, e - 257, 5), s(t, a - 1, 5), s(t, n - 4, 4), r = 0; n > r; r++) s(t, t.bl_tree[2 * ae[r] + 1], 3); y(t, t.dyn_ltree, e - 1), y(t, t.dyn_dtree, a - 1) } function x(t) { var e, a = 4093624447; for (e = 0; 31 >= e; e++, a >>>= 1) if (1 & a && 0 !== t.dyn_ltree[2 * e]) return U; if (0 !== t.dyn_ltree[18] || 0 !== t.dyn_ltree[20] || 0 !== t.dyn_ltree[26]) return q; for (e = 32; O > e; e++) if (0 !== t.dyn_ltree[2 * e]) return q; return U } function B(t) { ge || (u(), ge = !0), t.l_desc = new ce(t.dyn_ltree, _e), t.d_desc = new ce(t.dyn_dtree, de), t.bl_desc = new ce(t.bl_tree, ue), t.bi_buf = 0, t.bi_valid = 0, f(t) } function A(t, e, a, n) { s(t, (R << 1) + (n ? 1 : 0), 3), g(t, e, a, !0) } function C(t) { s(t, T << 1, 3), h(t, W, re), o(t) } function S(t, e, a, n) { var r, i, h = 0; t.level > 0 ? (t.strm.data_type === D && (t.strm.data_type = x(t)), v(t, t.l_desc), v(t, t.d_desc), h = z(t), r = t.opt_len + 3 + 7 >>> 3, i = t.static_len + 3 + 7 >>> 3, r >= i && (r = i)) : r = i = a + 5, r >= a + 4 && -1 !== e ? A(t, e, a, n) : t.strategy === I || i === r ? (s(t, (T << 1) + (n ? 1 : 0), 3), b(t, re, ie)) : (s(t, (H << 1) + (n ? 1 : 0), 3), k(t, t.l_desc.max_code + 1, t.d_desc.max_code + 1, h + 1), b(t, t.dyn_ltree, t.dyn_dtree)), f(t), n && c(t) } function E(t, e, a) { return t.pending_buf[t.d_buf + 2 * t.last_lit] = e >>> 8 & 255, t.pending_buf[t.d_buf + 2 * t.last_lit + 1] = 255 & e, t.pending_buf[t.l_buf + t.last_lit] = 255 & a, t.last_lit++, 0 === e ? t.dyn_ltree[2 * a]++ : (t.matches++, e--, t.dyn_ltree[2 * (he[a] + O + 1)]++, t.dyn_dtree[2 * r(e)]++), t.last_lit === t.lit_bufsize - 1 } var j = t("../utils/common"), I = 4, U = 0, q = 1, D = 2, R = 0, T = 1, H = 2, L = 3, K = 258, N = 29, O = 256, P = O + 1 + N, F = 30, G = 19, J = 2 * P + 1, M = 15, Q = 16, V = 7, W = 256, X = 16, Y = 17, Z = 18, $ = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0], te = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13], ee = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7], ae = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15], ne = 512, re = new Array(2 * (P + 2)); n(re); var ie = new Array(2 * F); n(ie); var se = new Array(ne); n(se); var he = new Array(K - L + 1); n(he); var le = new Array(N); n(le); var oe = new Array(F); n(oe); var _e, de, ue, fe = function (t, e, a, n, r) { this.static_tree = t, this.extra_bits = e, this.extra_base = a, this.elems = n, this.max_length = r, this.has_stree = t && t.length }, ce = function (t, e) { this.dyn_tree = t, this.max_code = 0, this.stat_desc = e }, ge = !1; a._tr_init = B, a._tr_stored_block = A, a._tr_flush_block = S, a._tr_tally = E, a._tr_align = C }, { "../utils/common": 2 }], 9: [function (t, e) { "use strict"; function a() { this.input = null, this.next_in = 0, this.avail_in = 0, this.total_in = 0, this.output = null, this.next_out = 0, this.avail_out = 0, this.total_out = 0, this.msg = "", this.state = null, this.data_type = 2, this.adler = 0 } e.exports = a }, {}] }, {}, [1])(1) });

    var tabIdToRef = {};
    var tabsImpressionsInfo = {};
    var requestsTemp = {};
    var pduQueue = [];
    var MAX_PIXEL_SIZE = 10;
    var HELLFIRE_VERSION = 2;
    var PARTIDO_TRACKING_URL = 'http://hellfire.axost.com:8000/v1/pixel';
    var TIMEOUT_INTERVAL = 3000;
    var timeoutHandle = window.setTimeout(sendPixel, TIMEOUT_INTERVAL);

    var isHellfireActivated = isActivated("hellfire");
    var isHellfireChristmasActivated = isActivated("hellfireChristmas");
    var isHellfireTestGroup = isActivated("hellfireTestGroup");

    function arrToLCMap(arr) {
        var result = {};
        arr.forEach(function (item) {
            result[item.toLowerCase()] = 1;
        });
        return result;
    }

    var EXCLUDED_TYPES = arrToLCMap([
        'image',
        'stylesheet'
    ]);

    var REQUEST_GOOD_HEADERS = arrToLCMap([
        "Accept",
        "Accept-Charset",
        "Accept-Encoding",
        "Accept-Language",
        "Content-Type",
        "Origin",
        "Pragma",
        "Range",
        "Referer",
        "User-Agent",
        "X-Forwarded-For",
        "X-HTTP-Method-Override",
        "X-Requested-With"
    ]);

    var REQUEST_HEADERS_TO_TRIM = arrToLCMap([
        "Referer"
    ]);

    var RESPONSE_GOOD_HEADERS = arrToLCMap([
        "Accept-Ranges",
        "Access-Control-Allow-Credentials",
        "Access-Control-Allow-Headers",
        "Access-Control-Allow-Methods",
        "Access-Control-Allow-Origin",
        "Access-Control-Expose-Headers",
        "Age",
        "Alternate-Protocol",
        "Cache-Control",
        "Connection",
        "Content-Encoding",
        "Content-Encoding",
        "Content-Length",
        "Content-Security-Policy",
        "Content-Type",
        "Date",
        "ETag",
        "Expires",
        "Keep-Alive",
        "Last-Modified",
        "Location",
        "P3P",
        "Pragma",
        "Server",
        "Status",
        "Strict-Transport-Security",
        "Timing-Allow-Origin",
        "Transfer-Encoding",
        "Vary",
        "Version",
        "Via",
        "X-Cache",
        "X-Content-Type-Options",
        "X-Content-Type-Options",
        "X-Frame-Options",
        "X-Powered-By",
        "X-XSS-Protection"
    ]);

    var RESPONSE_HEADERS_TO_TRIM = arrToLCMap([
        "Location"
    ]);

    var HF_DOMAIN_FILTERS = [
        /[.]facebook[.](com|net)$/,
        /^fbstatic-a[.]akamaihd[.]net$/,
        /^fbcdn-profile-a[.]akamaihd[.]net$/,
        /[.]google[.]com$/,
        /^www[.]google[.]/,
        /^pagead2[.]google/,
        /[.]doubleclick[.]net$/,
        /[.]googleapis[.]com$/,
        /[.]gstatic[.]com$/,
        /[.]google-analytics[.]com$/,
        /[.]googletagservices[.]com$/,
        /[.]googlesyndication[.]com$/,
        /[.]googleadservices[.]com$/,
        /[.]googleusercontent[.]com$/,
        /[.]googlejs[.]eu$/,
        /[.]ytimg[.]com$/,
        /[.]yimg[.]com$/,
        /^6ca4f4b68b959de96aaa/,
        /^localhost:26143$/,
        /[.]twitter[.]com$/,
        /[.]addthis[.]com$/,
        /[.]jquery[.]com$/,
        /[.]googlevideo[.]com$/
    ];

    // filter http header by goodHeaders arr
    function filterGoodHeaders(headers, goodHeaders) {
        if (!headers) return [];

        return headers.filter(function (header) {
            return goodHeaders[header.name.toLowerCase()];
        });
    }

    function trimSafe(str, maxLen) {
        if (typeof str === 'undefined') return str;
        if (str === null) return str;
        return str.substring(0, maxLen);
    }

    // trim trimHeaders values by HF_MAX_HEADER_LENGTH
    function trimHeaderValues(headers, trimHeaders) {
        if (typeof headers === 'undefined') return;
        headers.forEach(function (header) {
            if (trimHeaders[header.name.toLowerCase()])
                header.value = trimSafe(header.value, HF_MAX_HEADER_LENGTH);
        });
    }

    // extract domain and port from URL
    function extractDomain(url) {
        var a = document.createElement('a');
        a.href = url;
        var domain = a.hostname;
        if (a.port)
            domain += ":" + a.port;
        return domain;
    }

    // filter url by blacklist
    function filterHFUrl(url, type) {
        // don't filter if from main frame or sub frame
        if (type === "main_frame" || type === "sub_frame")
            return false;

        var domain = extractDomain(url);
        if (HF_DOMAIN_FILTERS.some(function (hdf) {
                return hdf.test(domain)
            })) {
            return true;
        }

        return false;
    }

    // get an existing tab info or create a new one if not exist
    function getOrCreateTab(tabId) {
        if (!tabsImpressionsInfo[tabId]) {
            tabsImpressionsInfo[tabId] = {
                currImprCreatingReqId: null,
                currImprId: null,
                currRefImprId: null,
                currRefFrameId: null,
                frames: {}
            };
        }
        return tabsImpressionsInfo[tabId];
    }

    // sends pixel to Rapid while breaking it to the required number of PDU's in pixel due to Rapid limitations
    function sendHfRapid(pixelPduArr, start, end, cb) {
        var arrToUse;
        cb = cb || function() {};

        if (typeof start === 'undefined') {
            arrToUse = pixelPduArr;
            start = 0;
            end = pixelPduArr.length;

        } else {
            arrToUse = pixelPduArr.slice(start, end);
        }

        var j = JSON.stringify(arrToUse);

        if (encodeURIComponent(j).length + 500 <= RAPID_MAX_PIXEL_SIZE) {
            sendRapid(j, SPACE_ID_HELLFIRE, undefined, undefined, function(err, extra) {
                if (typeof err === 'undefined') {
                    return cb();
                }
                log("ERROR: sendRapid(): unknown error [" + err + "], extra=[" + extra + "]");
                return cb(err, extra);
            });

        } else {
            var l = end - start;
            if (l === 1) {
                log("ERROR: sendRapid(): even one PDU is too large, can not send, failing");
                return cb('oversized');
            }
            var firstHalfLen = Math.ceil(l / 2);
            sendHfRapid(arrToUse, 0, firstHalfLen, function(err, extra) {
                if (err) log("ERROR: sendHfRapid(): 1st half: err=[" + err + "], extra=[" + extra + "]");
                sendHfRapid(arrToUse, firstHalfLen, end, function(err, extra) {
                    if (err) log("ERROR: sendHfRapid(): 2nd half: err=[" + err + "], extra=[" + extra + "]");
                    // TODO: return the aggregate of the 2 errors from the 2 callbacks
                    return cb();
                });
            });
        }
    }

    // Track an HF-format (not Bender-format) beacon to AWS and/or Rapid
    function sendPixel() {
        if (!loadValue("optin")) return false;

        // reset timer
        window.clearTimeout(timeoutHandle);
        timeoutHandle = window.setTimeout(sendPixel, TIMEOUT_INTERVAL);

        var n = Math.min(pduQueue.length, MAX_PIXEL_SIZE);
        if (n === 0) return;

        var pixelPduArr = pduQueue.splice(0, n);

        log("sending HF-format beacon", pixelPduArr);

        if (trackToRapid) {
            sendHfRapid(pixelPduArr);
        }

        if (trackToAws) {
            var j = JSON.stringify(pixelPduArr);
            var j_utf8_chars = unescape(encodeURIComponent(j));
            var uint8_array = new Uint8Array(j_utf8_chars.split('').map(function (x) {
                return x.charCodeAt(0);
            }));
            var postText = pako.deflate(uint8_array);

            var xhr = new XMLHttpRequest();
            xhr.open("POST", PARTIDO_TRACKING_URL, true);
            xhr.setRequestHeader("Content-Type", "application/json; charset=utf-8");
            xhr.setRequestHeader("Content-Encoding", "deflate");
            xhr.send(postText);
        }
    }

    var guid = (function () {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }

        return function () {
            return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
                s4() + '-' + s4() + s4() + s4();
        };
    })();

    function newImprInTab(tabId, creatingReqId) {
        var tabImprInfo = getOrCreateTab(tabId);
        var r = tabIdToRef[tabId];
        if (r) {
            // first impression in a tab created from another tab
            tabImprInfo.currRefImprId = r.refImprId;
            tabImprInfo.currRefFrameId = r.refFrameId;
            delete tabIdToRef[tabId];
        } else {
            // new impression for existing tab
            tabImprInfo.currRefImprId = tabImprInfo.currImprId;
            tabImprInfo.currRefFrameId = null;
        }

        tabImprInfo.currImprCreatingReqId = creatingReqId;
        tabImprInfo.currImprId = guid();
    }

    function newFrameInTab(tabId, frameId, parentFrameId) {

        var tabImprInfo = getOrCreateTab(tabId);
        var imprId;
        var refImprId;
        var refFrameId;

        // the frame may be from a previous impr in the tab. if the frame has a parent frame
        // and the parent frame is from a previous impr, then this frame also belongs to that impr.
        // if the frame does not have a parent frame then we assume it belongs to the current impr in the tab.

        var parentFrame;
        if (parentFrameId)
            parentFrame = tabImprInfo.frames[parentFrameId];

        if (parentFrame) {
            imprId = parentFrame.imprId;
            refImprId = parentFrame.refImprId;
            refFrameId = parentFrame.refFrameId;
        } else {
            imprId = tabImprInfo.currImprId;
            refImprId = tabImprInfo.currRefImprId;
            refFrameId = tabImprInfo.currRefFrameId;
        }

        tabImprInfo.frames[frameId] = {
            imprId: imprId,
            refImprId: refImprId,
            refFrameId: refFrameId
        };
    }

    function processRequestHellfire(details) {
        try {
            // nothing to do if request is not from a tab
            if (details.tabId === -1)
                return;

            // get or create tab impressions info
            var tabImprInfo = getOrCreateTab(details.tabId);

            // main_frame is always frameId === 0. a request should be considered a request FOR a main frame
            // (vs IN a main frame) when its type is "main_frame" obviously, but also if it's the first request
            // in frameId 0. this, because when opening a tab for a url such as http://.../a.jpg, Chrome will
            // set the type to 'image', and the frameId to 0.

            // a request FOR a main_frame creates a new impr IF the requestId is different than the last requestId
            // that created a new impr. this, because if a request gets redireceted, authRequired, etc. -- another request
            // will go out with the same requestId, and we don't want that request to start a new impr.

            var isMainFrameReq = (details.type === 'main_frame') || (details.frameId === 0 && !tabImprInfo.frames[0]);
            if (isMainFrameReq && tabImprInfo.currImprCreatingReqId !== details.requestId) {
                // request to main frame - new impression in tab
                newImprInTab(details.tabId, details.requestId);
                // new frame in that new impression
                newFrameInTab(details.tabId, details.frameId);
            } else if (!tabImprInfo.frames[details.frameId]) {
                // first time we're seeing a given frame
                newFrameInTab(details.tabId, details.frameId, details.parentFrameId);
            }

            // filter by type and black list only if not in test group
            if (!isHellfireTestGroup) {
                if (EXCLUDED_TYPES[details.type])
                    return;
                if (filterHFUrl(details.url, details.type))
                    return;
            }

            logRequest('hf', details, {
                is_test_group: isHellfireTestGroup,
                impr_id: tabImprInfo.frames[details.frameId].imprId,
                ref_impr_id: tabImprInfo.frames[details.frameId].refImprId,
                ref_frame_id: tabImprInfo.frames[details.frameId].refFrameId
            });

        } catch (e10) {
            trackError(10, e10.message, e10.name);
        }
    }

    function processRequestHellfireChristmas(details) {

        function isYahooUrl(url) {
            return url.match(/^https?:\/\/[^\/]*\b(yahoo|yahooapis|yimg|flickr|tumblr|txmblr)\.com\//i);
        }

        function isIrrelevantUrl(url) {
            return url.match(/^https?:\/\/[^\/]*\b(scorecardresearch\.com|cedexis\.com|cedexis-radar\.net|cedexis-test\.com)\//i);
        }

        function getReferer(details) {
        if (!details.requestHeaders) return;
            var refererHeaders = details.requestHeaders.filter(function(pair) { return pair.name.toLowerCase() === 'referer'});
            return refererHeaders.length > 0 ? refererHeaders[0].value : undefined;
        }

        try {
            // TODO: Handle requests not from tab (from extensions for example)
            // nothing to do if request is not from a tab
            if (details.tabId === -1)
                return;

            var referer = getReferer(details);
            if (referer && isYahooUrl(referer) && details.url && !isYahooUrl(details.url) && !isIrrelevantUrl(details.url)) {
                logRequest('hfx', details);
            }

        } catch (e41) {
            trackError(41, e41.message, e41.name);
        }
    }

    function logRequest(tag, details, extraReqFields) {
        // create request object
        var headers = filterGoodHeaders(details.requestHeaders, REQUEST_GOOD_HEADERS);
        trimHeaderValues(headers, REQUEST_HEADERS_TO_TRIM);
        var req = {
            req_id: details.requestId,
            method: details.method,
            url: trimSafe(details.url, HF_MAX_HEADER_LENGTH),
            headers: headers,
            ts_ux_ms: Math.floor(details.timeStamp),
            frame_id: details.frameId,
            parent_frame_id: details.parentFrameId,
            type: details.type
        };

        if (extraReqFields) {
            Object.keys(extraReqFields).forEach(function(k) { req[k] = extraReqFields[k]; });
        }

        if (!requestsTemp[details.requestId])
            requestsTemp[details.requestId] = {};
        requestsTemp[details.requestId][tag] = req;
    }

    // handles on completed, on error and on before redirect events
    function handleLastChainEvent(details) {
        try {
            var tagsToRequests = requestsTemp[details.requestId];

            // Return if no matching request found
            if (!tagsToRequests) {
                return;
            }

            if (pduQueue.length >= MAX_PIXEL_SIZE) {
                trackError(9, "PDU Queue length greater or equal to " + MAX_PIXEL_SIZE);
                return;
            }

            // create response object
            var res = {
                ts_ux_ms: Math.floor(details.timeStamp),
                type: details.type
            };
            if (typeof details.statusCode !== 'undefined')
            res.status = details.statusCode;

        if (typeof details.responseHeaders !== 'undefined') {
                var headers = filterGoodHeaders(details.responseHeaders, RESPONSE_GOOD_HEADERS);
                trimHeaderValues(headers, RESPONSE_HEADERS_TO_TRIM);
                res.headers = headers;
            }

            if (typeof details.error !== 'undefined')
            res.error = details.error;

        // create ext_cfg object
        var extensionVersion;
            try {
                extensionVersion = chrome.app.getDetails().version;
            } catch (e8) {
                trackError(8, e8.message, e8.name);
            }

            var ext_cfg = {
                ext_name: extensionConsts.extensionName,
                ext_ver: extensionVersion,
                rate: activations.hellfire
            };

            // couple respone and ext_cfg to each req
            Object.keys(tagsToRequests).forEach(function (tag) {
                // add new PDU to queue
                pduQueue.push({
                    req: tagsToRequests[tag],
                    res: res,
                    proto_ver: HELLFIRE_VERSION,
                    tag: tag,
                    ext_cfg: ext_cfg
                });

                while (pduQueue.length >= MAX_PIXEL_SIZE)
                    sendPixel();
            });

            delete requestsTemp[details.requestId];

        } catch (e7) {
            trackError(7, e7.message, e7.name);
        }
    }

    // saves the source tab and frame id's and updates the impression if already created
    function handleNavigationCreated(details) {
        if (details.sourceTabId === details.tabId) return;

        // WebNavigation gives us the exact source tab and source frameId in that tab which triggered the navigation.
        // from the source tabId we can extract the imprId in that tab. this should be the currRefImprId in the new tab.
        var r = {
            refImprId: tabsImpressionsInfo[details.sourceTabId].currImprId,
            refFrameId: details.sourceFrameId
        };

        // if WebRequest hasn't happened for the new tab yet,
        // we save the Ref information for this new tab to be picked-up by WebRequest when it happens,
        // and we are done.
        var tabImprInfo = tabsImpressionsInfo[details.tabId];
        if (!tabImprInfo) {
            tabIdToRef[details.tabId] = r;

            return;
        }

        // getting here means that the WebRequest in the new tab has already happened, specifically before
        // this WebNavigation. so the tab may (in current Chrome versions: does) have bad/missing/incomplete Ref information.

        // fill in what's missing in the tab's currRefXXX, for later WebRequests in the tab to pick up.
        // the server side will later use these correct requests to populate the other requests in the impr.
        if (!tabImprInfo.currRefImprId) {
            tabImprInfo.currRefImprId = r.refImprId;
            tabImprInfo.currRefFrameId = r.refFrameId;
        } else {
            if (tabImprInfo.currRefImprId === r.refImprId && !tabImprInfo.currRefFrameId)
                tabImprInfo.currRefFrameId = r.refFrameId;
        }

        // frames in the tab contain their own copy of {imprId,refImprId,refFrameId}
        // requests will copy their {imprId,refImprId,refFrameId} from the frames
        // so if we updated the tab's {currImprId,curRefImprId,currRefFrameId} that won't help future requests,
        // as those future requests will copy from the frame.
        // so update all frames in the tab (that are part of the current impr, as some may be from prev imprs)
        // to contain updated Ref info.
        Object.keys(tabImprInfo.frames).forEach(function (frameId) {
            var frame = tabImprInfo.frames[frameId];
            if (frame.imprId === tabImprInfo.currImprId) {
                frame.refImprId = tabImprInfo.currRefImprId;
                frame.refFrameId = tabImprInfo.currRefFrameId;
            }
        });
    }

    try {

        if (isHellfireActivated) {
            log("Hellfire activated");

            // listen to all on before send headers events
            chrome.webRequest.onBeforeSendHeaders.addListener(processRequestHellfire, { urls: ["*://*/*"] }, ["requestHeaders", "blocking"]);

            // listen to all new created windows or tabs for getting the opener tab id
            chrome.webNavigation.onCreatedNavigationTarget.addListener(handleNavigationCreated);
        }

        if (isHellfireChristmasActivated) {
            log("HellfireChristmas activated");

            // listen to all on before send headers events
            chrome.webRequest.onBeforeSendHeaders.addListener(processRequestHellfireChristmas, { urls: ["*://*/*"] }, ["requestHeaders", "blocking"]);
        }

        if (isHellfireActivated || isHellfireChristmasActivated) {
            // listen to all webRequest last chain events
            chrome.webRequest.onCompleted.addListener(handleLastChainEvent, {urls: ["*://*/*"]}, ["responseHeaders"]);
            chrome.webRequest.onAuthRequired.addListener(handleLastChainEvent, {urls: ["*://*/*"]}, ["responseHeaders"]);
            chrome.webRequest.onBeforeRedirect.addListener(handleLastChainEvent, {urls: ["*://*/*"]}, ["responseHeaders"]);
            chrome.webRequest.onErrorOccurred.addListener(handleLastChainEvent, {urls: ["*://*/*"]});
        }

    } catch (e6) {
        trackError(6, e6.message, e6.name);
    }
}