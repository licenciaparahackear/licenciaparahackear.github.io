<!--
.. title: Filtering my phone contacts with AWK
.. slug: filtrando-mis-contactos-del-celular-con-awk
.. date: 2021-06-26 19:38:49 UTC-03:00
.. tags: awk,unix,android
.. category: 
.. link: 
.. description: 
.. type: text
.. previewimage: /images/og-awk.png
-->

A few weeks ago I changed my Android cellphone for a newer one. I needed to
import my old phone's contacts into the new phone. Since I don't use cloud
storage solutions because of privacy reasons, I had to import the contacts
manually, using [vCard .vcf files][vcf].

[vcf]: https://en.wikipedia.org/wiki/VCard

Some years ago, when I still used Google services on my phone, the Gmail app
decided to create a phone contact for each user I have emailed to. This created
a lot of useless contacts. Contacts for whom I don't even know their phone
number, only their e-mail. Unsurprisingly, this turned out to be quite annoying.
I couldn't easily get rid of these new contacts, so I kept them even though I
knew I wouldn't use them.

Since I was already changing my phone, it was a good occasion to finally delete
all of these useless contacts. To do this, I would need to:

* Export my old phone contacts into a [.vcf file][vcf]
* Find or create a tool allowing me to programmatically delete the contacts
  without a phone number
* Save the output into a new .vcf file, ready for import into my new phone

In order to write the tool to filter contacts, I would need to parse a .vcf
file. Normally, I would have used Python to address the problem. I could have
relied on an [external library][python-vcard] and trust it didn't have any bugs
or vulnerabilities. Or maybe I could create my own .vcf/vCard parsing library,
properly tested and documented. However, both options looked very complicated
for the problem I intended to resolve. There had to be a simpler solution.

[python-vcard]: https://gitlab.com/victor-engmark/vcard

A .vcf file has the following format:

```
BEGIN:VCARD
VERSION:2.1
N:First Name;Last name;;;
FN:Visible Name
TEL;CELL:123-456-789
END:VCARD
BEGIN:VCARD
VERSION:2.1
N:Other;Contact;;;
FN:Other contact
EMAIL;PREF:user@gmail.com
END:VCARD
```

As you can see, the details of each contact are delimited by the lines
`BEGIN:VCARD` and `END:VCARD`. The .vcf format doesn't look complicated. It is
just plain text delimited by formatted lines.

Taking into account that .vcf files were simple, and that I only wanted to
filter through my contact list once, I used [AWK][awk] instead of Python. The
AWK language is relatively small, and you can learn it in a few hours. [Its
Wikipedia page][awk] looks good enough as an introduction.

[awk]: https://en.wikipedia.org/wiki/AWK

I took another look at the problem I wanted to solve, and built the following
AWK program:

```awk
# lines will save the lines of the contact being processed into an array.
# n represents the length of the lines array. It will increment on each
# iteration.
{
    lines[n++] = $0; # This is like append in Python
}

/^TEL;/ {
    # The contact being processed has a phone number, so I want to keep it
    has_phone_number = 1
}

/^END:VCARD/ { # I reached the end of the contact

    # If the contact had a phone number, keep it (print all the saved lines)
    if (has_phone_number)
        for (i=0; i<n; i++)
            print lines[i]

    # In the next iteration I'll use a different contact. Reset the program's
    # state.
    has_phone_number = 0
    n = 0 # This is like emptying the lines array
}
```

I ran the program with `awk -f program.awk <unfiltered-contacts.vcf >filtered-contacts.vcf`.
This created a new .vcf file that only contained the contacts with a phone
number. It was ready to be imported into my new cellphone.

With just 13 lines of code (discarding comments and blank lines), I made a
program that solved my problem perfectly. I didn't overthink it by installing
external libraries, creating big class hierarchies, nor making complex file
parsers.

It looks like I was way more productive using a 40-year old language than using
Python, my go-to language for most problems. Because AWK is intended to be used
for handling text files and writing throwaway programs, it was the perfect fit
for my problem. Maybe the code wasn't very maintainable, but I don't have
to care about it if I planned to discard the program after it ran
successfully. I needed a quick solution, and AWK succeeded at it.

I hope that with this short blogpost I explained the essence of the AWK
language. It is a fundamental tool for programmers and sysadmins. You can learn
the language in a few hours, and it will definitely be a productivity boost.

Here are a few useful resources I used when learning AWK:

* [Why Learn AWK](https://blog.jpalardy.com/posts/why-learn-awk/)
* AWK quickstart
  [part 1](https://jemma.dev/blog/awk-part-1) and
  [part 2](https://jemma.dev/blog/awk-part-2)
* ["An AWK love story"](https://www.youtube.com/watch?v=IfhMUed9RSE), for those
  who enjoy conference talks

There also exists [a book][libro] about the language written by their authors. I
can't recommend it since I haven't read it yet. But in case the resources above
make you want to learn more, this book will probably be a great choice.

[libro]: https://www.goodreads.com/book/show/703101.The_AWK_Programming_Language

Greetings!
