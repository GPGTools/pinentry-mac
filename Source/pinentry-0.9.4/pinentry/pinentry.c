/* pinentry.c - The PIN entry support library
   Copyright (C) 2002, 2003, 2007, 2008, 2010, 2015 g10 Code GmbH

   This file is part of PINENTRY.

   PINENTRY is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   PINENTRY is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, see <http://www.gnu.org/licenses/>.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifndef HAVE_W32CE_SYSTEM
# include <errno.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#ifndef HAVE_W32CE_SYSTEM
# include <locale.h>
#endif
#ifdef HAVE_LANGINFO_H
#include <langinfo.h>
#endif
#include <limits.h>
#ifdef HAVE_W32CE_SYSTEM
# include <windows.h>
#endif

#if defined FALLBACK_CURSES || defined PINENTRY_CURSES || defined PINENTRY_GTK
#include <iconv.h>
#endif

#include "assuan.h"
#include "memory.h"
#include "secmem-util.h"
#include "argparse.h"
#include "pinentry.h"
#include "password-cache.h"

#ifdef HAVE_W32CE_SYSTEM
#define getpid() GetCurrentProcessId ()
#endif

/* Keep the name of our program here. */
static char this_pgmname[50];

struct pinentry pinentry;

static void
pinentry_reset (int use_defaults)
{
  /* GPG Agent sets these options once when it starts the pinentry.
     Don't reset them.  */
  int grab = pinentry.grab;
  char *ttyname = pinentry.ttyname;
  char *ttytype = pinentry.ttytype;
  char *lc_ctype = pinentry.lc_ctype;
  char *lc_messages = pinentry.lc_messages;
  int allow_external_password_cache = pinentry.allow_external_password_cache;
  char *default_ok = pinentry.default_ok;
  char *default_cancel = pinentry.default_cancel;
  char *default_prompt = pinentry.default_prompt;
  char *default_pwmngr = pinentry.default_pwmngr;
  char *touch_file = pinentry.touch_file;

  /* These options are set from the command line.  Don't reset
     them.  */
  int debug = pinentry.debug;
  char *display = pinentry.display;
  int parent_wid = pinentry.parent_wid;

  pinentry_color_t color_fg = pinentry.color_fg;
  int color_fg_bright = pinentry.color_fg_bright;
  pinentry_color_t color_bg = pinentry.color_bg;
  pinentry_color_t color_so = pinentry.color_so;
  int color_so_bright = pinentry.color_so_bright;

  int timout = pinentry.timeout;

  /* Free any allocated memory.  */
  if (use_defaults)
    {
      free (pinentry.ttyname);
      free (pinentry.ttytype);
      free (pinentry.lc_ctype);
      free (pinentry.lc_messages);
      free (pinentry.default_ok);
      free (pinentry.default_cancel);
      free (pinentry.default_prompt);
      free (pinentry.default_pwmngr);
      free (pinentry.touch_file);
      free (pinentry.display);
    }

  free (pinentry.title);
  free (pinentry.description);
  free (pinentry.error);
  free (pinentry.prompt);
  free (pinentry.ok);
  free (pinentry.notok);
  free (pinentry.cancel);
  secmem_free (pinentry.pin);
  free (pinentry.repeat_passphrase);
  free (pinentry.repeat_error_string);
  free (pinentry.quality_bar);
  free (pinentry.quality_bar_tt);
  free (pinentry.keyinfo);

  /* Reset the pinentry structure.  */
  memset (&pinentry, 0, sizeof (pinentry));

  if (use_defaults)
    {
      /* Pinentry timeout in seconds.  */
      pinentry.timeout = 60;

      /* Global grab.  */
      pinentry.grab = 1;

      pinentry.color_fg = PINENTRY_COLOR_DEFAULT;
      pinentry.color_fg_bright = 0;
      pinentry.color_bg = PINENTRY_COLOR_DEFAULT;
      pinentry.color_so = PINENTRY_COLOR_DEFAULT;
      pinentry.color_so_bright = 0;
    }
  else
    /* Restore the options.  */
    {
      pinentry.grab = grab;
      pinentry.ttyname = ttyname;
      pinentry.ttytype = ttytype;
      pinentry.lc_ctype = lc_ctype;
      pinentry.lc_messages = lc_messages;
      pinentry.allow_external_password_cache = allow_external_password_cache;
      pinentry.default_ok = default_ok;
      pinentry.default_cancel = default_cancel;
      pinentry.default_prompt = default_prompt;
      pinentry.default_pwmngr = default_pwmngr;
      pinentry.touch_file = touch_file;

      pinentry.debug = debug;
      pinentry.display = display;
      pinentry.parent_wid = parent_wid;

      pinentry.color_fg = color_fg;
      pinentry.color_fg_bright = color_fg_bright;
      pinentry.color_bg = color_bg;
      pinentry.color_so = color_so;
      pinentry.color_so_bright = color_so_bright;

      pinentry.timeout = timout;
    }
}

static void
pinentry_assuan_reset_handler (ASSUAN_CONTEXT ctx)
{
  (void)ctx;
  pinentry_reset (0);
}



static int lc_ctype_unknown_warning = 0;

#if defined FALLBACK_CURSES || defined PINENTRY_CURSES || defined PINENTRY_GTK
char *
pinentry_utf8_to_local (const char *lc_ctype, const char *text)
{
  iconv_t cd;
  const char *input = text;
  size_t input_len = strlen (text) + 1;
  char *output;
  size_t output_len;
  char *output_buf;
  size_t processed;
  char *old_ctype;
  char *target_encoding;

  /* If no locale setting could be determined, simply copy the
     string.  */
  if (!lc_ctype)
    {
      if (! lc_ctype_unknown_warning)
	{
	  fprintf (stderr, "%s: no LC_CTYPE known - assuming UTF-8\n",
		   this_pgmname);
	  lc_ctype_unknown_warning = 1;
	}
      return strdup (text);
    }

  old_ctype = strdup (setlocale (LC_CTYPE, NULL));
  if (!old_ctype)
    return NULL;
  setlocale (LC_CTYPE, lc_ctype);
  target_encoding = nl_langinfo (CODESET);
  if (!target_encoding)
    target_encoding = "?";
  setlocale (LC_CTYPE, old_ctype);
  free (old_ctype);

  /* This is overkill, but simplifies the iconv invocation greatly.  */
  output_len = input_len * MB_LEN_MAX;
  output_buf = output = malloc (output_len);
  if (!output)
    return NULL;

  cd = iconv_open (target_encoding, "UTF-8");
  if (cd == (iconv_t) -1)
    {
      fprintf (stderr, "%s: can't convert from UTF-8 to %s: %s\n",
               this_pgmname, target_encoding, strerror (errno));
      free (output_buf);
      return NULL;
    }
  processed = iconv (cd, (ICONV_CONST char **)&input, &input_len,
                     &output, &output_len);
  iconv_close (cd);
  if (processed == (size_t) -1 || input_len)
    {
      fprintf (stderr, "%s: error converting from UTF-8 to %s: %s\n",
               this_pgmname, target_encoding, strerror (errno));
      free (output_buf);
      return NULL;
    }
  return output_buf;
}

/* Convert TEXT which is encoded according to LC_CTYPE to UTF-8.  With
   SECURE set to true, use secure memory for the returned buffer.
   Return NULL on error. */
char *
pinentry_local_to_utf8 (char *lc_ctype, char *text, int secure)
{
  char *old_ctype;
  char *source_encoding;
  iconv_t cd;
  const char *input = text;
  size_t input_len = strlen (text) + 1;
  char *output;
  size_t output_len;
  char *output_buf;
  size_t processed;

  /* If no locale setting could be determined, simply copy the
     string.  */
  if (!lc_ctype)
    {
      if (! lc_ctype_unknown_warning)
	{
	  fprintf (stderr, "%s: no LC_CTYPE known - assuming UTF-8\n",
		   this_pgmname);
	  lc_ctype_unknown_warning = 1;
	}
      output_buf = secure? secmem_malloc (input_len) : malloc (input_len);
      if (output_buf)
        strcpy (output_buf, input);
      return output_buf;
    }

  old_ctype = strdup (setlocale (LC_CTYPE, NULL));
  if (!old_ctype)
    return NULL;
  setlocale (LC_CTYPE, lc_ctype);
  source_encoding = nl_langinfo (CODESET);
  setlocale (LC_CTYPE, old_ctype);
  free (old_ctype);

  /* This is overkill, but simplifies the iconv invocation greatly.  */
  output_len = input_len * MB_LEN_MAX;
  output_buf = output = secure? secmem_malloc (output_len):malloc (output_len);
  if (!output)
    return NULL;

  cd = iconv_open ("UTF-8", source_encoding);
  if (cd == (iconv_t) -1)
    {
      fprintf (stderr, "%s: can't convert from %s to UTF-8: %s\n",
               this_pgmname, source_encoding? source_encoding : "?",
               strerror (errno));
      if (secure)
        secmem_free (output_buf);
      else
        free (output_buf);
      return NULL;
    }
  processed = iconv (cd, (ICONV_CONST char **)&input, &input_len,
                     &output, &output_len);
  iconv_close (cd);
  if (processed == (size_t) -1 || input_len)
    {
      fprintf (stderr, "%s: error converting from %s to UTF-8: %s\n",
               this_pgmname, source_encoding? source_encoding : "?",
               strerror (errno));
      if (secure)
        secmem_free (output_buf);
      else
        free (output_buf);
      return NULL;
    }
  return output_buf;
}
#endif


/* Copy TEXT or TEXTLEN to BUFFER and escape as required.  Return a
   pointer to the end of the new buffer.  Note that BUFFER must be
   large enough to keep the entire text; allocataing it 3 times of
   TEXTLEN is sufficient.  */
static char *
copy_and_escape (char *buffer, const void *text, size_t textlen)
{
  int i;
  const unsigned char *s = (unsigned char *)text;
  char *p = buffer;

  for (i=0; i < textlen; i++)
    {
      if (s[i] < ' ' || s[i] == '+')
        {
          snprintf (p, 4, "%%%02X", s[i]);
          p += 3;
        }
      else if (s[i] == ' ')
        *p++ = '+';
      else
        *p++ = s[i];
    }
  return p;
}



/* Run a quality inquiry for PASSPHRASE of LENGTH.  (We need LENGTH
   because not all backends might be able to return a proper
   C-string.).  Returns: A value between -100 and 100 to give an
   estimate of the passphrase's quality.  Negative values are use if
   the caller won't even accept that passphrase.  Note that we expect
   just one data line which should not be escaped in any represent a
   numeric signed decimal value.  Extra data is currently ignored but
   should not be send at all.  */
int
pinentry_inq_quality (pinentry_t pin, const char *passphrase, size_t length)
{
  ASSUAN_CONTEXT ctx = pin->ctx_assuan;
  const char prefix[] = "INQUIRE QUALITY ";
  char *command;
  char *line;
  size_t linelen;
  int gotvalue = 0;
  int value = 0;
  int rc;

  if (!ctx)
    return 0; /* Can't run the callback.  */

  if (length > 300)
    length = 300;  /* Limit so that it definitely fits into an Assuan
                      line.  */

  command = secmem_malloc (strlen (prefix) + 3*length + 1);
  if (!command)
    return 0;
  strcpy (command, prefix);
  copy_and_escape (command + strlen(command), passphrase, length);
  rc = assuan_write_line (ctx, command);
  secmem_free (command);
  if (rc)
    {
      fprintf (stderr, "ASSUAN WRITE LINE failed: rc=%d\n", rc);
      return 0;
    }

  for (;;)
    {
      do
        {
          rc = assuan_read_line (ctx, &line, &linelen);
          if (rc)
            {
              fprintf (stderr, "ASSUAN READ LINE failed: rc=%d\n", rc);
              return 0;
            }
        }
      while (*line == '#' || !linelen);
      if (line[0] == 'E' && line[1] == 'N' && line[2] == 'D'
          && (!line[3] || line[3] == ' '))
        break; /* END command received*/
      if (line[0] == 'C' && line[1] == 'A' && line[2] == 'N'
          && (!line[3] || line[3] == ' '))
        break; /* CAN command received*/
      if (line[0] == 'E' && line[1] == 'R' && line[2] == 'R'
          && (!line[3] || line[3] == ' '))
        break; /* ERR command received*/
      if (line[0] != 'D' || line[1] != ' ' || linelen < 3 || gotvalue)
        continue;
      gotvalue = 1;
      value = atoi (line+2);
    }
  if (value < -100)
    value = -100;
  else if (value > 100)
    value = 100;

  return value;
}



/* Try to make room for at least LEN bytes in the pinentry.  Returns
   new buffer on success and 0 on failure or when the old buffer is
   sufficient.  */
char *
pinentry_setbufferlen (pinentry_t pin, int len)
{
  char *newp;

  if (pin->pin_len)
    assert (pin->pin);
  else
    assert (!pin->pin);

  if (len < 2048)
    len = 2048;

  if (len <= pin->pin_len)
    return pin->pin;

  newp = secmem_realloc (pin->pin, len);
  if (newp)
    {
      pin->pin = newp;
      pin->pin_len = len;
    }
  else
    {
      secmem_free (pin->pin);
      pin->pin = 0;
      pin->pin_len = 0;
    }
  return newp;
}

static void
pinentry_setbuffer_clear (pinentry_t pin)
{
  if (! pin->pin)
    {
      assert (pin->pin_len == 0);
      return;
    }

  assert (pin->pin_len > 0);

  secmem_free (pin->pin);
  pin->pin = NULL;
  pin->pin_len = 0;
}

static void
pinentry_setbuffer_init (pinentry_t pin)
{
  pinentry_setbuffer_clear (pin);
  pinentry_setbufferlen (pin, 0);
}

/* passphrase better be alloced with secmem_alloc.  */
void
pinentry_setbuffer_use (pinentry_t pin, char *passphrase, int len)
{
  if (! passphrase)
    {
      assert (len == 0);
      pinentry_setbuffer_clear (pin);

      return;
    }

  if (passphrase && len == 0)
    len = strlen (passphrase) + 1;

  if (pin->pin)
    secmem_free (pin->pin);

  pin->pin = passphrase;
  pin->pin_len = len;
}

/* Initialize the secure memory subsystem, drop privileges and return.
   Must be called early. */
void
pinentry_init (const char *pgmname)
{
  /* Store away our name. */
  if (strlen (pgmname) > sizeof this_pgmname - 2)
    abort ();
  strcpy (this_pgmname, pgmname);

  /* Initialize secure memory.  1 is too small, so the default size
     will be used.  */
  secmem_init (1);
  secmem_set_flags (SECMEM_WARN);
  drop_privs ();

  if (atexit (secmem_term))
    {
      /* FIXME: Could not register at-exit function, bail out.  */
    }

  assuan_set_malloc_hooks (secmem_malloc, secmem_realloc, secmem_free);
}

/* Simple test to check whether DISPLAY is set or the option --display
   was given.  Used to decide whether the GUI or curses should be
   initialized.  */
int
pinentry_have_display (int argc, char **argv)
{
#ifndef HAVE_W32CE_SYSTEM
  const char *s;

  s = getenv ("DISPLAY");
  if (s && *s)
    return 1;
#endif
  for (; argc; argc--, argv++)
    if (!strcmp (*argv, "--display") || !strncmp (*argv, "--display=", 10))
      return 1;
  return 0;
}



/* Print usage information and and provide strings for help. */
static const char *
my_strusage( int level )
{
  const char *p;

  switch (level)
    {
    case 11: p = this_pgmname; break;
    case 12: p = "pinentry"; break;
    case 13: p = PACKAGE_VERSION; break;
    case 14: p = "Copyright (C) 2015 g10 Code GmbH"; break;
    case 19: p = "Please report bugs to <" PACKAGE_BUGREPORT ">.\n"; break;
    case 1:
    case 40:
      {
        static char *str;

        if (!str)
          {
            size_t n = 50 + strlen (this_pgmname);
            str = malloc (n);
            if (str)
              snprintf (str, n, "Usage: %s [options] (-h for help)",
                        this_pgmname);
          }
        p = str;
      }
      break;
    case 41:
      p = "Ask securely for a secret and print it to stdout.";
      break;

    case 42:
      p = "1"; /* Flag print 40 as part of 41. */
      break;

    default: p = NULL; break;
    }
  return p;
}


char *
parse_color (char *arg, pinentry_color_t *color_p, int *bright_p)
{
  static struct
  {
    const char *name;
    pinentry_color_t color;
  } colors[] = { { "none", PINENTRY_COLOR_NONE },
		 { "default", PINENTRY_COLOR_DEFAULT },
		 { "black", PINENTRY_COLOR_BLACK },
		 { "red", PINENTRY_COLOR_RED },
		 { "green", PINENTRY_COLOR_GREEN },
		 { "yellow", PINENTRY_COLOR_YELLOW },
		 { "blue", PINENTRY_COLOR_BLUE },
		 { "magenta", PINENTRY_COLOR_MAGENTA },
		 { "cyan", PINENTRY_COLOR_CYAN },
		 { "white", PINENTRY_COLOR_WHITE } };

  int i;
  char *new_arg;
  pinentry_color_t color = PINENTRY_COLOR_DEFAULT;

  if (!arg)
    return NULL;

  new_arg = strchr (arg, ',');
  if (new_arg)
    new_arg++;

  if (bright_p)
    {
      const char *bname[] = { "bright-", "bright", "bold-", "bold" };

      *bright_p = 0;
      for (i = 0; i < sizeof (bname) / sizeof (bname[0]); i++)
	if (!strncasecmp (arg, bname[i], strlen (bname[i])))
	  {
	    *bright_p = 1;
	    arg += strlen (bname[i]);
	  }
    }

  for (i = 0; i < sizeof (colors) / sizeof (colors[0]); i++)
    if (!strncasecmp (arg, colors[i].name, strlen (colors[i].name)))
      color = colors[i].color;

  *color_p = color;
  return new_arg;
}

/* Parse the command line options.  May exit the program if only help
   or version output is requested.  */
void
pinentry_parse_opts (int argc, char *argv[])
{
  static ARGPARSE_OPTS opts[] = {
    ARGPARSE_s_n('d', "debug",    "Turn on debugging output"),
    ARGPARSE_s_s('D', "display",  "|DISPLAY|Set the X display"),
    ARGPARSE_s_s('T', "ttyname",  "|FILE|Set the tty terminal node name"),
    ARGPARSE_s_s('N', "ttytype",  "|NAME|Set the tty terminal type"),
    ARGPARSE_s_s('C', "lc-ctype", "|STRING|Set the tty LC_CTYPE value"),
    ARGPARSE_s_s('M', "lc-messages", "|STRING|Set the tty LC_MESSAGES value"),
    ARGPARSE_s_i('o', "timeout",
                 "|SECS|Timeout waiting for input after this many seconds"),
    ARGPARSE_s_n('g', "no-global-grab",
                 "Grab keyboard only while window is focused"),
    ARGPARSE_s_u('W', "parent-wid", "Parent window ID (for positioning)"),
    ARGPARSE_s_s('c', "colors", "|STRING|Set custom colors for ncurses"),
    ARGPARSE_end()
  };
  ARGPARSE_ARGS pargs = { &argc, &argv, 0 };

  set_strusage (my_strusage);

  pinentry_reset (1);

  while (arg_parse  (&pargs, opts))
    {
      switch (pargs.r_opt)
        {
        case 'd':
          pinentry.debug = 1;
          break;
        case 'g':
          pinentry.grab = 0;
          break;

	case 'D':
          /* Note, this is currently not used because the GUI engine
             has already been initialized when parsing these options. */
	  pinentry.display = strdup (pargs.r.ret_str);
	  if (!pinentry.display)
	    {
#ifndef HAVE_W32CE_SYSTEM
	      fprintf (stderr, "%s: %s\n", this_pgmname, strerror (errno));
#endif
	      exit (EXIT_FAILURE);
	    }
	  break;
	case 'T':
	  pinentry.ttyname = strdup (pargs.r.ret_str);
	  if (!pinentry.ttyname)
	    {
#ifndef HAVE_W32CE_SYSTEM
	      fprintf (stderr, "%s: %s\n", this_pgmname, strerror (errno));
#endif
	      exit (EXIT_FAILURE);
	    }
	  break;
	case 'N':
	  pinentry.ttytype = strdup (pargs.r.ret_str);
	  if (!pinentry.ttytype)
	    {
#ifndef HAVE_W32CE_SYSTEM
	      fprintf (stderr, "%s: %s\n", this_pgmname, strerror (errno));
#endif
	      exit (EXIT_FAILURE);
	    }
	  break;
	case 'C':
	  pinentry.lc_ctype = strdup (pargs.r.ret_str);
	  if (!pinentry.lc_ctype)
	    {
#ifndef HAVE_W32CE_SYSTEM
	      fprintf (stderr, "%s: %s\n", this_pgmname, strerror (errno));
#endif
	      exit (EXIT_FAILURE);
	    }
	  break;
	case 'M':
	  pinentry.lc_messages = strdup (pargs.r.ret_str);
	  if (!pinentry.lc_messages)
	    {
#ifndef HAVE_W32CE_SYSTEM
	      fprintf (stderr, "%s: %s\n", this_pgmname, strerror (errno));
#endif
	      exit (EXIT_FAILURE);
	    }
	  break;
	case 'W':
	  pinentry.parent_wid = pargs.r.ret_ulong;
	  break;

	case 'c':
          {
            char *tmpstr = pargs.r.ret_str;

            tmpstr = parse_color (tmpstr, &pinentry.color_fg,
                                  &pinentry.color_fg_bright);
            tmpstr = parse_color (tmpstr, &pinentry.color_bg, NULL);
            tmpstr = parse_color (tmpstr, &pinentry.color_so,
                                  &pinentry.color_so_bright);
          }
	  break;

	case 'o':
	  pinentry.timeout = pargs.r.ret_int;
	  break;

        default:
          pargs.err = ARGPARSE_PRINT_WARNING;
	  break;
        }
    }
}


static int
option_handler (ASSUAN_CONTEXT ctx, const char *key, const char *value)
{
  (void)ctx;

  if (!strcmp (key, "no-grab") && !*value)
    pinentry.grab = 0;
  else if (!strcmp (key, "grab") && !*value)
    pinentry.grab = 1;
  else if (!strcmp (key, "debug-wait"))
    {
#ifndef HAVE_W32CE_SYSTEM
      fprintf (stderr, "%s: waiting for debugger - my pid is %u ...\n",
	       this_pgmname, (unsigned int) getpid());
      sleep (*value?atoi (value):5);
      fprintf (stderr, "%s: ... okay\n", this_pgmname);
#endif
    }
  else if (!strcmp (key, "display"))
    {
      if (pinentry.display)
	free (pinentry.display);
      pinentry.display = strdup (value);
      if (!pinentry.display)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "ttyname"))
    {
      if (pinentry.ttyname)
	free (pinentry.ttyname);
      pinentry.ttyname = strdup (value);
      if (!pinentry.ttyname)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "ttytype"))
    {
      if (pinentry.ttytype)
	free (pinentry.ttytype);
      pinentry.ttytype = strdup (value);
      if (!pinentry.ttytype)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "lc-ctype"))
    {
      if (pinentry.lc_ctype)
	free (pinentry.lc_ctype);
      pinentry.lc_ctype = strdup (value);
      if (!pinentry.lc_ctype)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "lc-messages"))
    {
      if (pinentry.lc_messages)
	free (pinentry.lc_messages);
      pinentry.lc_messages = strdup (value);
      if (!pinentry.lc_messages)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "parent-wid"))
    {
      pinentry.parent_wid = atoi (value);
      /* FIXME: Use strtol and add some error handling.  */
    }
  else if (!strcmp (key, "touch-file"))
    {
      if (pinentry.touch_file)
        free (pinentry.touch_file);
      pinentry.touch_file = strdup (value);
      if (!pinentry.touch_file)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "default-ok"))
    {
      pinentry.default_ok = strdup (value);
      if (!pinentry.default_ok)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "default-cancel"))
    {
      pinentry.default_cancel = strdup (value);
      if (!pinentry.default_cancel)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "default-prompt"))
    {
      pinentry.default_prompt = strdup (value);
      if (!pinentry.default_prompt)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "default-pwmngr"))
    {
      pinentry.default_pwmngr = strdup (value);
      if (!pinentry.default_pwmngr)
	return ASSUAN_Out_Of_Core;
    }
  else if (!strcmp (key, "allow-external-password-cache") && !*value)
    {
      pinentry.allow_external_password_cache = 1;
      pinentry.tried_password_cache = 0;
    }
  else if (!strcmp (key, "cache-id"))
  {
	  pinentry.cache_id = strdup (value);
	  if (!pinentry.cache_id)
    return ASSUAN_Out_Of_Core;
  }
  else
    return ASSUAN_Invalid_Option;
  return 0;
}


/* Note, that it is sufficient to allocate the target string D as
   long as the source string S, i.e.: strlen(s)+1; */
static void
strcpy_escaped (char *d, const char *s)
{
  while (*s)
    {
      if (*s == '%' && s[1] && s[2])
        {
          s++;
          *d++ = xtoi_2 ( s);
          s += 2;
        }
      else
        *d++ = *s++;
    }
  *d = 0;
}


static int
cmd_setdesc (ASSUAN_CONTEXT ctx, char *line)
{
  char *newd;

  (void)ctx;

  newd = malloc (strlen (line) + 1);
  if (!newd)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (newd, line);
  if (pinentry.description)
    free (pinentry.description);
  pinentry.description = newd;
  return 0;
}


static int
cmd_setprompt (ASSUAN_CONTEXT ctx, char *line)
{
  char *newp;

  (void)ctx;

  newp = malloc (strlen (line) + 1);
  if (!newp)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (newp, line);
  if (pinentry.prompt)
    free (pinentry.prompt);
  pinentry.prompt = newp;
  return 0;
}


/* The data provided at LINE may be used by pinentry implementations
   to identify a key for caching strategies of its own.  The empty
   string and --clear mean that the key does not have a stable
   identifier.  */
static int
cmd_setkeyinfo (ASSUAN_CONTEXT ctx, char *line)
{
  (void)ctx;

  if (pinentry.keyinfo)
    free (pinentry.keyinfo);

  if (*line && strcmp(line, "--clear") != 0)
    pinentry.keyinfo = strdup (line);
  else
    pinentry.keyinfo = NULL;

  return 0;
}


static int
cmd_setrepeat (ASSUAN_CONTEXT ctx, char *line)
{
  char *p;

  (void)ctx;

  p = malloc (strlen (line) + 1);
  if (!p)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (p, line);
  free (pinentry.repeat_passphrase);
  pinentry.repeat_passphrase = p;
  return 0;
}


static int
cmd_setrepeaterror (ASSUAN_CONTEXT ctx, char *line)
{
  char *p;

  (void)ctx;

  p = malloc (strlen (line) + 1);
  if (!p)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (p, line);
  free (pinentry.repeat_error_string);
  pinentry.repeat_error_string = p;
  return 0;
}


static int
cmd_seterror (ASSUAN_CONTEXT ctx, char *line)
{
  char *newe;

  (void)ctx;

  newe = malloc (strlen (line) + 1);
  if (!newe)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (newe, line);
  if (pinentry.error)
    free (pinentry.error);
  pinentry.error = newe;
  return 0;
}


static int
cmd_setok (ASSUAN_CONTEXT ctx, char *line)
{
  char *newo;

  (void)ctx;

  newo = malloc (strlen (line) + 1);
  if (!newo)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (newo, line);
  if (pinentry.ok)
    free (pinentry.ok);
  pinentry.ok = newo;
  return 0;
}


static int
cmd_setnotok (ASSUAN_CONTEXT ctx, char *line)
{
  char *newo;

  (void)ctx;

  newo = malloc (strlen (line) + 1);
  if (!newo)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (newo, line);
  if (pinentry.notok)
    free (pinentry.notok);
  pinentry.notok = newo;
  return 0;
}


static int
cmd_setcancel (ASSUAN_CONTEXT ctx, char *line)
{
  char *newc;

  (void)ctx;

  newc = malloc (strlen (line) + 1);
  if (!newc)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (newc, line);
  if (pinentry.cancel)
    free (pinentry.cancel);
  pinentry.cancel = newc;
  return 0;
}


static int
cmd_settimeout (ASSUAN_CONTEXT ctx, char *line)
{
  (void)ctx;

  if (line && *line)
    pinentry.timeout = atoi (line);

  return 0;
}

static int
cmd_settitle (ASSUAN_CONTEXT ctx, char *line)
{
  char *newt;

  (void)ctx;

  newt = malloc (strlen (line) + 1);
  if (!newt)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (newt, line);
  if (pinentry.title)
    free (pinentry.title);
  pinentry.title = newt;
  return 0;
}

static int
cmd_setqualitybar (ASSUAN_CONTEXT ctx, char *line)
{
  char *newval;

  (void)ctx;

  if (!*line)
    line = "Quality:";

  newval = malloc (strlen (line) + 1);
  if (!newval)
    return ASSUAN_Out_Of_Core;

  strcpy_escaped (newval, line);
  if (pinentry.quality_bar)
    free (pinentry.quality_bar);
  pinentry.quality_bar = newval;
  return 0;
}

/* Set the tooltip to be used for a quality bar.  */
static int
cmd_setqualitybar_tt (ASSUAN_CONTEXT ctx, char *line)
{
  char *newval;

  (void)ctx;

  if (*line)
    {
      newval = malloc (strlen (line) + 1);
      if (!newval)
        return ASSUAN_Out_Of_Core;

      strcpy_escaped (newval, line);
    }
  else
    newval = NULL;
  if (pinentry.quality_bar_tt)
    free (pinentry.quality_bar_tt);
  pinentry.quality_bar_tt = newval;
  return 0;
}


static int
cmd_getpin (ASSUAN_CONTEXT ctx, char *line)
{
  int result;
  int set_prompt = 0;
  int just_read_password_from_cache = 0;

  (void)line;

  pinentry_setbuffer_init (&pinentry);
  if (!pinentry.pin)
    return ASSUAN_Out_Of_Core;

  /* Try reading from the password cache.  */
  if (/* If repeat passphrase is set, then we don't want to read from
	 the cache.  */
      ! pinentry.repeat_passphrase
      /* Are we allowed to read from the cache?  */
      && pinentry.allow_external_password_cache
      && pinentry.keyinfo
      /* Only read from the cache if we haven't already tried it.  */
      && ! pinentry.tried_password_cache
      /* If the last read resulted in an error, then don't read from
	 the cache.  */
      && ! pinentry.error)
    {
      char *password;

      pinentry.tried_password_cache = 1;

      password = password_cache_lookup (pinentry.keyinfo);
      if (password)
	/* There is a cached password.  Try it.  */
	{
	  int len = strlen(password) + 1;
	  if (len > pinentry.pin_len)
	    len = pinentry.pin_len;

	  memcpy (pinentry.pin, password, len);
	  pinentry.pin[len] = '\0';

	  secmem_free (password);

	  pinentry.pin_from_cache = 1;

	  assuan_write_status (ctx, "PASSWORD_FROM_CACHE", "");

	  /* Result is the length of the password not including the
	     NUL terminator.  */
	  result = len - 1;

	  just_read_password_from_cache = 1;

	  goto out;
	}
    }

  /* The password was not cached (or we are not allowed to / cannot
     use the cache).  Prompt the user.  */
  pinentry.pin_from_cache = 0;

  if (!pinentry.prompt)
    {
      pinentry.prompt = pinentry.default_prompt?pinentry.default_prompt:"PIN:";
      set_prompt = 1;
    }
  pinentry.locale_err = 0;
  pinentry.specific_err = 0;
  pinentry.close_button = 0;
  pinentry.repeat_okay = 0;
  pinentry.one_button = 0;
  pinentry.ctx_assuan = ctx;
  result = (*pinentry_cmd_handler) (&pinentry);
  pinentry.ctx_assuan = NULL;
  if (pinentry.error)
    {
      free (pinentry.error);
      pinentry.error = NULL;
    }
  if (pinentry.repeat_passphrase)
    {
      free (pinentry.repeat_passphrase);
      pinentry.repeat_passphrase = NULL;
    }
  if (set_prompt)
    pinentry.prompt = NULL;

  pinentry.quality_bar = 0;  /* Reset it after the command.  */

  if (pinentry.close_button)
    assuan_write_status (ctx, "BUTTON_INFO", "close");

  if (result < 0)
    {
      pinentry_setbuffer_clear (&pinentry);
      if (pinentry.specific_err)
        return pinentry.specific_err;
      return pinentry.locale_err? ASSUAN_Locale_Problem: ASSUAN_Canceled;
    }

 out:
  if (result)
    {
      if (pinentry.repeat_okay)
        assuan_write_status (ctx, "PIN_REPEATED", "");
      result = assuan_send_data (ctx, pinentry.pin, strlen(pinentry.pin));
      if (!result)
	result = assuan_send_data (ctx, NULL, 0);

      if (/* GPG Agent says it's okay.  */
	  pinentry.allow_external_password_cache && pinentry.keyinfo
	  /* We didn't just read it from the cache.  */
	  && ! just_read_password_from_cache
	  /* And the user said it's okay.  */
	  && pinentry.may_cache_password)
	/* Cache the password.  */
	password_cache_save (pinentry.keyinfo, pinentry.pin);
    }

  pinentry_setbuffer_clear (&pinentry);

  return result;
}


/* Note that the option --one-button is a hack to allow the use of old
   pinentries while the caller is ignoring the result.  Given that
   options have never been used or flagged as an error the new option
   is an easy way to enable the messsage mode while not requiring to
   update pinentry or to have the caller test for the message
   command.  New applications which are free to require an updated
   pinentry should use MESSAGE instead. */
static int
cmd_confirm (ASSUAN_CONTEXT ctx, char *line)
{
  int result;

  pinentry.one_button = !!strstr (line, "--one-button");
  pinentry.quality_bar = 0;
  pinentry.close_button = 0;
  pinentry.locale_err = 0;
  pinentry.specific_err = 0;
  pinentry.canceled = 0;
  pinentry_setbuffer_clear (&pinentry);
  result = (*pinentry_cmd_handler) (&pinentry);
  if (pinentry.error)
    {
      free (pinentry.error);
      pinentry.error = NULL;
    }

  if (pinentry.close_button)
    assuan_write_status (ctx, "BUTTON_INFO", "close");

  if (result)
    return 0;

  if (pinentry.specific_err)
    return pinentry.specific_err;

  if (pinentry.locale_err)
    return ASSUAN_Locale_Problem;

  if (pinentry.one_button)
    return 0;

  if (pinentry.canceled)
    return ASSUAN_Canceled;
  return ASSUAN_Not_Confirmed;
}


static int
cmd_message (ASSUAN_CONTEXT ctx, char *line)
{
  (void)line;

  return cmd_confirm (ctx, "--one-button");
}

/* GETINFO <what>

   Multipurpose function to return a variety of information.
   Supported values for WHAT are:

     version     - Return the version of the program.
     pid         - Return the process id of the server.
 */
static int
cmd_getinfo (assuan_context_t ctx, char *line)
{
  int rc;

  if (!strcmp (line, "version"))
    {
      const char *s = VERSION;
      rc = assuan_send_data (ctx, s, strlen (s));
    }
  else if (!strcmp (line, "pid"))
    {
      char numbuf[50];

      snprintf (numbuf, sizeof numbuf, "%lu", (unsigned long)getpid ());
      rc = assuan_send_data (ctx, numbuf, strlen (numbuf));
    }
  else
    rc = ASSUAN_Parameter_Error;
  return rc;
}

/* CLEARPASSPHRASE <cacheid>

   Clear the cache passphrase associated with the key identified by
   cacheid.
 */
static int
cmd_clear_passphrase (ASSUAN_CONTEXT ctx, char *line)
{
  (void)ctx;

  if (! line)
    return ASSUAN_Invalid_Value;

  /* Remove leading and trailing white space.  */
  while (*line == ' ')
    line ++;
  while (line[strlen (line) - 1] == ' ')
    line[strlen (line) - 1] = 0;

  switch (password_cache_clear (line))
    {
    case 1: return 0;
    case 0: return ASSUAN_Invalid_Value;
    default: return ASSUAN_General_Error;
    }
}

/* Tell the assuan library about our commands.  */
static int
register_commands (ASSUAN_CONTEXT ctx)
{
  static struct
  {
    const char *name;
    int cmd_id;
    int (*handler) (ASSUAN_CONTEXT, char *line);
  } table[] =
    {
      { "SETDESC",    0,  cmd_setdesc },
      { "SETPROMPT",  0,  cmd_setprompt },
      { "SETKEYINFO", 0,  cmd_setkeyinfo },
      { "SETREPEAT",  0,  cmd_setrepeat },
      { "SETREPEATERROR",0, cmd_setrepeaterror },
      { "SETERROR",   0,  cmd_seterror },
      { "SETOK",      0,  cmd_setok },
      { "SETNOTOK",   0,  cmd_setnotok },
      { "SETCANCEL",  0,  cmd_setcancel },
      { "GETPIN",     0,  cmd_getpin },
      { "CONFIRM",    0,  cmd_confirm },
      { "MESSAGE",    0,  cmd_message },
      { "SETQUALITYBAR", 0,  cmd_setqualitybar },
      { "SETQUALITYBAR_TT", 0,  cmd_setqualitybar_tt },
      { "GETINFO",    0,  cmd_getinfo },
      { "SETTITLE",   0,  cmd_settitle },
      { "SETTIMEOUT",   0,  cmd_settimeout },
      { "CLEARPASSPHRASE", 0, cmd_clear_passphrase },
      { NULL }
    };
  int i, j, rc;

  for (i = j = 0; table[i].name; i++)
    {
      rc = assuan_register_command (ctx,
                                    table[i].cmd_id ? table[i].cmd_id
                                                   : (ASSUAN_CMD_USER + j++),
                                    table[i].name, table[i].handler);
      if (rc)
        return rc;
    }
  return 0;
}


int
pinentry_loop2 (int infd, int outfd)
{
  int rc;
  int filedes[2];
  ASSUAN_CONTEXT ctx;

  /* Extra check to make sure we have dropped privs. */
#ifndef HAVE_DOSISH_SYSTEM
  if (getuid() != geteuid())
    abort ();
#endif

  /* For now we use a simple pipe based server so that we can work
     from scripts.  We will later add options to run as a daemon and
     wait for requests on a Unix domain socket.  */
  filedes[0] = infd;
  filedes[1] = outfd;
  rc = assuan_init_pipe_server (&ctx, filedes);
  if (rc)
    {
      fprintf (stderr, "%s: failed to initialize the server: %s\n",
               this_pgmname, assuan_strerror(rc));
      return -1;
    }
  rc = register_commands (ctx);
  if (rc)
    {
      fprintf (stderr, "%s: failed to the register commands with Assuan: %s\n",
               this_pgmname, assuan_strerror(rc));
      return -1;
    }

  assuan_register_option_handler (ctx, option_handler);
#if 0
  assuan_set_log_stream (ctx, stderr);
#endif
  assuan_register_reset_notify (ctx, pinentry_assuan_reset_handler);

  for (;;)
    {
      rc = assuan_accept (ctx);
      if (rc == -1)
          break;
      else if (rc)
        {
          fprintf (stderr, "%s: Assuan accept problem: %s\n",
                   this_pgmname, assuan_strerror (rc));
          break;
        }

      rc = assuan_process (ctx);
      if (rc)
        {
          fprintf (stderr, "%s: Assuan processing failed: %s\n",
                   this_pgmname, assuan_strerror (rc));
          continue;
        }
    }

  assuan_deinit_server (ctx);
  return 0;
}


/* Start the pinentry event loop.  The program will start to process
   Assuan commands until it is finished or an error occurs.  If an
   error occurs, -1 is returned.  Otherwise, 0 is returned.  */
int
pinentry_loop (void)
{
  return pinentry_loop2 (STDIN_FILENO, STDOUT_FILENO);
}
