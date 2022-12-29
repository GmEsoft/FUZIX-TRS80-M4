#include <stdio.h>
#include <io.h>
#include <ctype.h>
#include <stddef.h>
#include <string.h>

#include <fcntl.h>    // O_RDWR...
#include <sys/stat.h> // S_IWRITE

#define PATCH "PATCH - File Patching Utility, (C) 2019-20 by GmEsoft"

typedef unsigned char uchar;
typedef unsigned int uint;
typedef unsigned long ulong;

static int debug = 0;
static int verbose = 0;

void help()
{
	puts(
		"PATCH\n"
		"Alters the contents of a disk file\n"
		"\n"
		"Command line method:\n"
		"\n"
		" PATCH filespec (patch commands)\n"
		"\n"
		"Patch commands:\n"
		"X'hhhh'=aa bb...    Changes data at address hhhh to value aa, hhhh+1 to bb\n"
		"Dr,b=aa bb ...      Changes data at byte b in record r to aa, b+1 to bb\n"
		"Fr,b=aa bb ...      Finds string aa bb... at byte b in record r; Use with\n"
		"                    D patch or REMOVE\n"
		"Lnn                 Use to patch a library command\n"
		"\n"
		"File method:\n"
		"\n"
		" PATCH filespec1 [USING] filespec2 [(parameter)]\n"
		"\n"
		"Parameters:\n"
		"Yank          Eliminates the results of an X'hhhh' type patch\n"
		"Remove        Eliminates the results of an Dr|Fr type patch\n"
		"O=N           Option to override match of \"Fr,...\" statements\n"
	);
}

const char* gethexbyte( const char *s, int *byte )
{
	int i;

	*byte = 0;
	for ( i=0; i<2; ++i )
	{
		char c = toupper( *s );
		*byte <<= 4;
		if ( isdigit( c ) )
		{
			*byte += c - '0';
		}
		else if ( c >= 'A' && c <= 'F' )
		{
			*byte += c - 'A' + 10;
		}
		else
		{
			*byte = -1;
			break;
		}
		++s;
	}

	if ( debug )
		printf( "$$$ gethexbyte %02X\n", *byte );

	return s;
}

const char * getlong( const char *s, ulong *pvalue)
{
	int hexfound = 0, ishex;
	ulong dec = 0, hex = 0;
	char c;

	if ( ishex = ( s[0] == '0' && toupper( s[1] ) == 'X' ) )
	{
		s += 2;
	}

	while ( isalnum( c = toupper( *s ) ) )
	{
		++s;
		if ( c <= 'F' )
		{
			c -= '0';
			if ( c > 9 )
			{
				c -= 'A' - '9' - 1;
				hexfound = 1;
			}
			dec *= 10; dec += c;
			hex <<= 4; hex += c;
		}
		else
		{
			if ( c == 'H' )
				ishex = 1;
			break;
		}
	}

	*pvalue= ishex ? hex : dec;

	if ( debug )
		printf( "$$$ getlong %08lX\n", *pvalue );

	return s;
}

const char * getoffset( const char *s, ulong *poffset )
{
	s = getlong( s, poffset );

	if ( *s == ',' )
	{
		long byte;
		++s;
		*poffset <<= 8;
		s = getlong( s, &byte );
		*poffset += byte;
	}
	return s;
}

const char * getbytes( const char *s, char *buf, int *plen )
{
	int len = 260;
	int i=0;

	*plen = 0;

	if ( *s == '"' )
	{
		++s;
		while ( *s && *s != '"' )
		{
			if ( len-- > 0 )
			{
				++*plen;
				buf[i++] = *s++;
			}
		}
		if ( *s == '"' )
			++s;
	}
	else
	{
		while ( *s && len-- > 0 )
		{
			int byte;
			s = gethexbyte( s, &byte );
			if ( byte == -1 )
				break;
			++*plen;
			buf[i++] = byte;
			if ( *s != ' ' )
				break;
			++s;
		}
	}

	if ( verbose )
	{
		printf( "$$$ %d bytes:", *plen );
		for ( i=0; i<*plen; ++i )
			printf( " %02X", (uchar)buf[i] );
		printf( "\n" );
	}
	return s;
}

const char* skipblk( const char *s )
{
	while ( *s == ' ' )
		++s;
	return s;
}

const char* chkchr( const char *s, char c )
{
	if ( *s == c )
		++s;
	else
	{
		printf( "*** '%c' expected: %s\n", c, s );
		s = 0;
	}
	return s;
}

int apply( int file, long findoffset, char *find, int nfind, long dataoffset, char *data, int ndata )
{
	char buffer[260];
	int len;
	int ret = 0;
	unsigned long pos;

	if ( verbose )
		printf( "apply( %d, %08lX, %p, %d, %08lX, %p, %d )\n",
			file, findoffset, find, nfind, dataoffset, data, ndata );

	if ( ndata )
	{
		if ( nfind )
		{
			if ( findoffset != dataoffset )
			{
				printf( "*** find offset (%08lX) differs from data offset (%08lX)\n", findoffset, dataoffset );
				return 1;
			}
			if ( nfind != ndata )
			{
				printf( "*** # of bytes to match (%d) differs from # of data bytes (%d)\n", nfind, ndata );
				return 1;
			}
			pos = lseek( file, findoffset, SEEK_SET );
			if ( debug )
				printf( "$$$ pos=%08lX\n", pos );
			if ( pos != findoffset )
			{
				printf( "*** lseek: Offset %08lX beyond end of file %08lX\n", findoffset, pos );
				return 1;
			}
			len = read( file, buffer, nfind );
			if ( len != nfind )
			{
				printf( "*** read: End of file encountered\n", findoffset, pos );
				return 1;
			}
			if ( strncmp( buffer, find, nfind ) )
			{
				int i;

				printf( "*** Find bytes mismatch:\nTo find:" );
				for ( i=0; i<nfind; ++i )
				{
					printf( " %02x", find[i] );
				}
				printf( "\n  Found:" );
				for ( i=0; i<nfind; ++i )
				{
					printf( "%c%02x", buffer[i] == find[i] ? ' ' : '!', buffer[i] );
				}
				printf( "\n" );
				return 1;
			}
		}

		pos = lseek( file, dataoffset, SEEK_SET );
		if ( debug )
			printf( "$$$ pos=%08lX\n", pos );
		if ( pos != dataoffset )
		{
			printf( "*** lseek: Offset %08lX beyond end of file %08lX\n", findoffset, pos );
			return 1;
		}
		len = write( file, data, ndata );
		if ( len != nfind )
		{
			printf( "*** write: End of file encountered\n", findoffset, pos );
			return 1;
		}

	}

	return ret;
}

const char *patch( const char *s, int file )
{
	static char find[260], data[260];
	static int nfind = 0, ndata = 0;
	static unsigned long findoffset = 0, dataoffset = 0;

	char c;

	if ( !*s )
		return s;

	if ( debug )
		printf( "$$$ Command: %s\n", s );

	switch ( c = toupper( *s++ ) )
	{
	case 'X':	// Extend .CMD
		puts( "*** X'hhhh'= not implemented" );
		s = 0;
		break;
	case 'D':	// Data
		if ( ndata )
		{
			if ( apply( file, findoffset, find, nfind, dataoffset, data, ndata ) )
			{
				s = 0;
				break;
			}
			ndata = nfind = 0;
		}
		s = getoffset( s, &dataoffset );
		if ( !( s = chkchr( s, '=' ) ) )
			break;
		s = getbytes( s, data, &ndata );
		break;
	case 'F':	// Find
		s = getoffset( s, &findoffset );
		if ( !( s = chkchr( s, '=' ) ) )
			break;
		s = getbytes( s, find, &nfind );
		break;
	case 'E':	// End
		if ( apply( file, findoffset, find, nfind, dataoffset, data, ndata ) )
			s = 0;
		break;
	case 'R':	// Remove
		break;
	case 'Y':	// Yank
		break;
	case 'O':	// Option=Y|N
		break;
	case '@':	// File mode
		break;
	default:
		printf( "*** Unrecognized command: %c%s\n", c, s );
		s = 0;
	}

	if ( ndata && nfind )
	{
		if ( apply( file, findoffset, find, nfind, dataoffset, data, ndata ) )
			s = 0;
		ndata = nfind = 0;
	}

	return s;
}

int main( int argc, char* argv[] )
{
	int 	file = 0;
	int 	patchfile = 0;
	char	params[255] = "";

	int		i;

	puts( PATCH "\n\n" );

	for ( i=1; i<argc; ++i )
	{
		char *s = argv[i];
		char c = 0;

		//puts(s);
		if ( *s == '-' )
		{
			++s;
			switch ( toupper( *s ) )
			{
			case 'D':
				debug = 1;
			case 'V':
				verbose = 1;
				break;
			case '?':
				help();
				return 0;
			default:
				printf( "### Unrecognized switch: -%s\n", s );
				printf( "PATCH -? for help.\n" );
				return 1;
			}
		}
		else
		{
			if ( *params )
			{
				strcat( params, " " );
				strcat( params, s );
				s = &params[strlen( params ) - 1];
				if ( *s == ')' )
				{
					*s = 0;
					++i;
					break;
				}
			}
			else if ( !strcmpi( s, "USING" ) )
			{
				if ( !file )
				{
					puts( "*** Missing filename before USING" );
					return 1;
				}
			}
			else if ( *s == '(' )
			{
				strcpy( params, ++s );
				s = &params[strlen( params ) - 1];
				if ( *s == ')' )
				{
					*s = 0;
					++i;
					break;
				}
			}
			else if ( !file )
			{
				printf( "### Patch file '%s'\n", s );
				file = open( (const char *)s, _O_RDWR | _O_BINARY, _S_IREAD );
			}
			else if ( !patchfile )
			{
				printf( "### Using file '%s'\n", s );
				patchfile = open( (const char *)s, _O_RDWR, _S_IREAD );
			}

		}

		if ( errno )
		{
			puts( strerror( errno ) );
			return 1;
		}
	}

	if ( i < argc )
		printf( "*** Extra parameters ignored starting from '%s'\n", argv[i] );

	printf ( "### Parameters: %s\n", params );

	if ( patchfile )
	{
		const char *s = params;

		patch( "@", file );

		while ( *s )
		{
			s = skipblk( s );
			if ( !( s = patch( s, file ) ) )
				break;
			s = skipblk( s );
			if ( *s )
				if ( !( s = chkchr( s, ',' ) ) )
					break;
		}

		if ( s )
		{
			puts( "### Applying patch from file" );
			patch( "E", file );
		}
	}
	else
	{
		const char *s = params;

		while ( s && *s )
		{
			s = skipblk( s );
			if ( !( s = patch( s, file ) ) )
				break;
			s = skipblk( s );
			if ( *s )
				if ( !( s = chkchr( s, ';' ) ) )
					break;
		}
	}

	return 0;
}
