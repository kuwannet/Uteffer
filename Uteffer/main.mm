//
//  main.cpp
//  Uteffer
//
//  Created by Dave Thorup on 3/2/21.
//

#include <iostream>
#include <codecvt>
#include <vector>
#include <locale>

#ifdef __OBJC__
#   import <Foundation/Foundation.h>
#endif

//  -- Byte Arrays starting with a "byte order mark" (BOM) --
//  Big Endian byte array              v- BOM --v  v- NULL -v
auto empty8_be = std::vector<uint8_t>{ 0xFE, 0xFF, 0x00, 0x00 };
//  Little Endian byte array           v- BOM --v  v- NULL -v
auto empty8_le = std::vector<uint8_t>{ 0xFF, 0xFE, 0x00, 0x00 };
//  Big Endian byte array              v- BOM --v  v- Euro -v  v- NULL -v
auto euro8_be  = std::vector<uint8_t>{ 0xFE, 0xFF, 0x20, 0xAC, 0x00, 0x00 };
//  Little Endian byte array           v- BOM --v  v- Euro -v  v- NULL -v
auto euro8_le  = std::vector<uint8_t>{ 0xFF, 0xFE, 0xAC, 0x20, 0x00, 0x00 };

//  -- 16-bit Arrays starting with BOM --
//  Big Endian - Empty String             BOM     NULL
auto empty16_be = std::vector<char16_t>{ 0xFEFF, 0x0000 };
//  Little Endian  - Empty String         BOM     NULL
auto empty16_le = std::vector<char16_t>{ 0xFFFE, 0x0000 };
//  Big Endian - Euro Char                BOM     Euro    NULL
auto euro16_be  = std::vector<char16_t>{ 0xFEFF, 0x20AC, 0x0000 };
//  Little Endian - Euro Char             BOM     Euro    NULL
auto euro16_le  = std::vector<char16_t>{ 0xFFFE, 0xAC20, 0x0000 };

void printStr( std::string s, std::string label )
{
    std::cout << label << " = '" << s << "', size = " << s.size() << ", empty = " << s.empty() << " ( ";
    
    for ( auto c : s )
    {
        std::cout << std::showbase << std::hex << int( uint8_t( c ) ) << " ";
    }
    
    std::cout << ")" << std::endl;
    std::cout << std::noshowbase << std::dec;
}

#ifdef __OBJC__

template <typename Container>
std::string utf16ToUtf8( const Container & data )
{
    @autoreleasepool
    {
        auto bytes = data.data();
        auto length = data.size() * sizeof( typename Container::value_type );
        auto nsStr = [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF16StringEncoding];
        auto str = std::string( nsStr.UTF8String );
        
        return str;
    }
}

void printNSString()
{
    auto sEmpty8_be = utf16ToUtf8( empty8_be );
    auto sEmpty8_le = utf16ToUtf8( empty8_le );
    auto sEuro8_be = utf16ToUtf8( euro8_be );
    auto sEuro8_le = utf16ToUtf8( euro8_le );
    
    auto sEmpty16_be = utf16ToUtf8( empty16_be );
    auto sEmpty16_le = utf16ToUtf8( empty16_le );
    auto sEuro16_be = utf16ToUtf8( euro16_be );
    auto sEuro16_le = utf16ToUtf8( euro16_le );
    
    std::cout << "-- NSString --" << std::endl;

    printStr( sEmpty8_be,  "Empty8_be " );
    printStr( sEmpty16_be, "Empty16_be" );
    printStr( sEuro8_be,   "Euro8_be  " );
    printStr( sEuro16_be,  "Euro16_be " );
    std::cout << std::endl;

    printStr( sEmpty8_le,  "Empty8_le " );
    printStr( sEmpty16_le, "Empty16_le" );
    printStr( sEuro8_le,   "Euro8_le  " );
    printStr( sEuro16_le,  "Euro16_le " );

    std::cout << std::endl;
}

#endif  //  #ifdef __OBJC__

template <std::codecvt_mode Mode>
void printWithMode()
{
    using toUtf16 = std::codecvt_utf8_utf16< char16_t, 0x10ffff, Mode >;
    std::wstring_convert< toUtf16, char16_t > cnv;

    //  NOTE: The _be/_le labeling here (to indicate Big/Little endian) on the strings refers to how the data
    //  will be interpreted after casting to char16_t.
    //  Just performing the cast here without properly byte-swapping the underlying data means that the
    //  endianness will be reversed (on Little Endian hardware). For my purposes though that should be irrelevant.
    //  To properly convert UTF-16 data you must look at the BOM to determine the endianness. So whether it's
    //  byte-swapped or not doesn't matter, the converter should look at the BOM & handle it properly.
    auto sEmpty8_be = cnv.to_bytes( reinterpret_cast<const char16_t *>( empty8_le.data() ) );
    auto sEmpty8_le = cnv.to_bytes( reinterpret_cast<const char16_t *>( empty8_be.data() ) );
    auto sEuro8_be = cnv.to_bytes( reinterpret_cast<const char16_t *>( euro8_le.data() ) );
    auto sEuro8_le = cnv.to_bytes( reinterpret_cast<const char16_t *>( euro8_be.data() ) );

    auto sEmpty16_be = cnv.to_bytes( empty16_be.data() );
    auto sEmpty16_le = cnv.to_bytes( empty16_le.data() );
    auto sEuro16_be = cnv.to_bytes( euro16_be.data() );
    auto sEuro16_le = cnv.to_bytes( euro16_le.data() );

    std::cout << "-- Mode = " << Mode << " --" << std::endl;
    
    //  Output Correctly
    std::cout << "Correct:" << std::endl;
    printStr( sEmpty8_be,  "Empty8_be " );
    printStr( sEmpty16_be, "Empty16_be" );
    printStr( sEuro8_be,   "Euro8_be  " );
    printStr( sEuro16_be,  "Euro16_be " );
    std::cout << std::endl;

    //  Output Incorrectly
    std::cout << "Incorrect:" << std::endl;
    printStr( sEmpty8_le,  "Empty8_le " );
    printStr( sEmpty16_le, "Empty16_le" );
    printStr( sEuro8_le,   "Euro8_le  " );
    printStr( sEuro16_le,  "Euro16_le " );

    std::cout << std::endl;
}

int main(int argc, const char * argv[])
{
    printWithMode<std::codecvt_mode::little_endian>();
    printWithMode<std::codecvt_mode::consume_header>();

#ifdef __OBJC__
    printNSString();
#endif
    
    return 0;
}
