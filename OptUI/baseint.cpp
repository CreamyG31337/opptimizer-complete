#include "ap.h"


// The baseint functions
// Baseints are basically bigints, but the base is not the rawtype maximum, but Base

const double base = 4294967296.0;               // 2^32
const double invbase = 1.0 / 4294967296.0;      // 2^-32
const double eps = 1.0 / 4503599627370496.0;    // 2^-52

// Adds n words from s to d, returns overflow carry bit
rawtype baseadd (rawtype *dest, rawtype *src1, rawtype *src2, size_t len, rawtype carry)
{
    size_t t;

    for (t = len; t--;)
    {
        dest[t] = src1[t] + carry;
        if (src2) dest[t] += src2[t];
        if (dest[t] >= Base)
        {
            dest[t] -= Base;
            carry = 1;
        }
        else
        {
            carry = 0;
        }
    }

    return carry;
}

// Subtracts n words s from d, returns subtract carry bit (1)
rawtype basesub (rawtype *dest, rawtype *src1, rawtype *src2, size_t len, rawtype carry)
{
    size_t t;
    rawtype tmp;

    for (t = len; t--;)
    {
        dest[t] = (src1 ? src1[t] : 0);
        tmp = (src2 ? src2[t] : 0) + carry;
        if ((int) (dest[t] -= tmp) < 0)
        {
            dest[t] += Base;
            carry = 1;
        }
        else
        {
            carry = 0;
        }
    }

    return carry;
}

// Multiplicates n words in s by f, adds s2, stores result to d, returns overflow word
rawtype basemuladd (rawtype *dest, rawtype *src1, rawtype *src2, rawtype src3, size_t len, rawtype carry)
{
    size_t t;
    rawtype rl, rh, tmp[2];
    double invf;

    if (Base == 0x40000000)     // Optimized case for bases 2, 4, 8 and 32
    {
        for (t = len; t--;)
        {
            tmp[0] = src1[t] * src3;
            tmp[1] = (rawtype) (invbase * ((double) src1[t] * (double) src3 - (double) (tmp[0] & 0x80000000)));

            tmp[0] += carry;
            if (tmp[0] < carry) tmp[1]++;

            if (src2)
            {
                tmp[0] += src2[t];
                if (tmp[0] < src2[t]) tmp[1]++;
            }

            carry = (tmp[0] >> 30) + (tmp[1] << 2);

            dest[t] = tmp[0] & 0x3FFFFFFF;                                // b = r % f;
        }
    }
    else
    {
        invf = (1.0 - 2.0 * eps) / (double) Base;     // Round down

        for (t = len; t--;)
        {
            tmp[0] = src1[t] * src3;
            tmp[1] = (rawtype) (invbase * ((double) src1[t] * (double) src3 - (double) (tmp[0] & 0x80000000)));

            tmp[0] += carry;
            if (tmp[0] < carry) tmp[1]++;

            if (src2)
            {
                tmp[0] += src2[t];
                if (tmp[0] < src2[t]) tmp[1]++;
            }

            carry = (rawtype) (invf * ((double) tmp[0] + base * (double) tmp[1]));

            rl = carry * Base;
            rh = (rawtype) (invbase * ((double) carry * (double) Base - (double) (rl & 0x80000000)));

            rl = tmp[0] - rl;
            rh = tmp[1] - rh;
            if (rl > tmp[0]) rh--;

            if (rh || rl >= Base) carry++;

            dest[t] = tmp[0] - carry * Base;                                // b = r % f;
        }
    }

    return carry;
}

// Divides n words in s by f, stores result in d, returns remainder
rawtype basediv (rawtype *dest, rawtype *src1, rawtype src2, size_t len, rawtype carry)
{
    size_t t;
    rawtype rl, rh, tmp[2];
    double invf = (1.0 - 2.0 * eps) / (double) src2;     // Round down

    if (Base == 0x40000000)     // Optimized case for bases 2, 4, 8 and 32
    {
        for (t = 0; t < len; t++)
        {
            tmp[0] = carry << 30;
            tmp[1] = carry >> 2;

            if (src1)
            {
                tmp[0] |= src1[t];
            }

            dest[t] = (rawtype) (invf * ((double) tmp[0] + base * (double) tmp[1]));

            rl = dest[t] * src2;
            rh = (rawtype) (invbase * ((double) dest[t] * (double) src2 - (double) (rl & 0x80000000)));

            rl = tmp[0] - rl;
            rh = tmp[1] - rh;
            if (rl > tmp[0]) rh--;

            if (rh || rl >= src2) dest[t]++;

            carry = tmp[0] - dest[t] * src2;                                 // b = r % f;
        }
    }
    else
    {
        for (t = 0; t < len; t++)
        {
            tmp[0] = carry * Base;
            tmp[1] = (rawtype) (invbase * ((double) carry * (double) Base - (double) (tmp[0] & 0x80000000)));

            if (src1)
            {
                tmp[0] += src1[t];
                if (tmp[0] < src1[t]) tmp[1]++;
            }

            dest[t] = (rawtype) (invf * ((double) tmp[0] + base * (double) tmp[1]));

            rl = dest[t] * src2;
            rh = (rawtype) (invbase * ((double) dest[t] * (double) src2 - (double) (rl & 0x80000000)));

            rl = tmp[0] - rl;
            rh = tmp[1] - rh;
            if (rl > tmp[0]) rh--;

            if (rh || rl >= src2) dest[t]++;

            carry = tmp[0] - dest[t] * src2;                                 // b = r % f;
        }
    }

    return carry;
}
