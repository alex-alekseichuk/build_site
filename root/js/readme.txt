These files are used in ./comp_root/queue/print_queue.mas.
  <param name="Path" value="/obj-lib/sxlic.mlf">
  <param name="Revision" value="5">
  codebase="http://xxxxxxxxxx/smsx.cab#Version=6,1,432,1"
================================================================
From: "Jerry Mead" <feedback@meadroid.com>
To: "Mark D. Anderson" <mda@discerning.com>
Cc: "Carrie Sawtell" <carrie@buildsite.com>,
    "Kay Chang" <kchang@buildsite.com>
Subject: Revision 5 of your ScriptX publishing license
Date: Mon, 24 Jan 2005 20:18:06 -0000
Organization: MeadCo

Hi Mark

Your payment was advised today (thank you) so I am very pleased to have
posted a zip containing a revision of your publishing license which is now
valid:

   FROM="2/16/2003" TO="2/18/2006"

It is here:

  http://www.d-boss.com/temp/buildsite-05.zip

+++++++++++++++++++++++++

As before, please read and carry out ALL of the following deployment
instructions VERY carefully to ensure a painless update.

+++++++++++++++++++++++++

What you should do now is to find *every* existing copy of sxlic.mlf on your
servers and overwrite them all with the file extracted from
buildsite-05.zip.

This is Revision "5" of your publishing license. To force a license update
for those users who already have your current license installed,  you should
update the value of the Revision parameter on ALL your existing and future
on-page Security Manager object scripts like so:

  <param name="Revision" value="5">

Once again, I stress the importance of finding and overwriting EVERY
existing copy of sxlic.mlf with this new file. If you do that rigorously,
then this extension deployment will go smoothly.

Also please make sure that ALL your document's Security Manager object's
'Path' parameters are 'pointing' to the location of this copy of sxlic.mlf:

  <param name="Path" value="http://xxxxxxxxxx/sxlic.mlf">

+++++++++++++++++++++++++
VERY IMPORTANT
+++++++++++++++++++++++++

This revised license file has been signed with our new (annually issued)
VeriSign keys.

You may currently have an earlier version of the ScriptX binaries deployed
which may be able to read this new digital signature.

However if you encounter any errors saying "unable to read digital
signature" or similar, then you will have to update to the current
6,1,432,1 version of the binaries:

  http://www.meadroid.com/scriptx/smsx.cab

To deploy this new version of smsx.cab,  download it and copy it over
*every* existing copy of smsx.cab on your servers.

Then update the Codebase versioning on ALL your ScriptX-enabled pages to
read:

  6,1,432,1

Also please make sure that the 'Codebase' attributes on ALL your documents
are 'pointing' to the location of this new copy of smsx.cab.

  codebase="http://xxxxxxxxxx/smsx.cab#Version=6,1,432,1"

+++++++++++++++++++++++++

Note 1:  If you have any users working with Windows XP SP2, then you *must*
make this update to remain compatible with MSFT's changes to the OS/browser.

More XP SP2 info is here:

  http://www.meadroid.com/scriptx/xpsp2.asp

+++++++++++++++++++++++++

Note 2: If you are working from Windows Server 2003 you will need to define
a MIME type in IIS 6.0 for the MLF file_type (application/octet-stream).

  http://support.microsoft.com/default.aspx?scid=kb;en-us;326965

If you cannot re-start your web services, the MIME setting for the .mlf file
must be entered at the WEBSITE level, not at the WEB SERVER level.
Apparently the site level setting will activate "on the fly" while the
global/server setting does not.

+++++++++++++++++++++++++

Note 3: The logged-on-local-admin-only-to-run installation executable for
6,1,432,1 is here should you need it:

  http://www.meadroid.com/scriptx/smsx.exe

+++++++++++++++++++++++++

As usual, please let me know of any deployment quirks (there should be none)
and we'll try to assist.

Best wishes

Jerry

MeadCo

++++++++++++++++++++++++
Goodbye to the monocular web.
MeadCo's Zeepe 7.1 is on release:
http://www.zeepe.com/
++++++++++++++++++++++++

Date: Fri, 27 Feb 2004 15:12:26 -0000
From: Jerry Mead <feedback@meadroid.com>
To: Holly Trytten <holly@buildsite.com>
Subject: Revision 3 of your ScriptX publishing license

Hi Holly

Your payment was notified today (thank you) so I am pleased to attach a zip
containing a revision of your publishing license which is now valid:

   FROM="2/16/2003" TO="2/18/2005"

As before, please read and carry out the following deployment instructions
VERY carefully to ensure a painless update.

+++++++++++++++++++++++++

What you should do now is to find *every* existing copy of sxlic.mlf on your
servers and overwrite them all with the file extracted from the attached
sxlic3.zip.

This is Revision "3" of your publishing license. To force a license update
for those users who already have your current license installed,  you should
update the value of the Revision parameter on ALL your existing and future
on-page Security Manager object scripts like so:

  <param name="Revision" value="3">

Once again, I stress the importance of finding and overwriting EVERY
existing copy of sxlic.mlf with this new file. If you do that rigorously,
then this extension deployment will go smoothly.

Also please make sure that ALL your document's Security Manager object's
'Path' parameters are 'pointing' to the location of this copy of sxlic.mlf:

<param name="Path" value="http://xxxxxxxxxx/sxlic.mlf">

+++++++++++++++++++++++++
VERY IMPORTANT
+++++++++++++++++++++++++

The current version of smsx.cab --  6,1,431,2 -- is available here:

  http://www.meadroid.com/scriptx/smsx.cab

If you haven't already done so, you MUST (repeat MUST) download and update
to this build now so that the digital signing of your revised MLF file can
be read.

To deploy this new version of smsx.cab,  download it and copy it over
*every* existing copy of smsx.cab on your servers.

Then update the Codebase versioning of the Security Manager and ScriptX
objects on ALL your ScriptX-enabled pages to read:

  6,1,431,2

Also please make sure that BOTH of the Security Manager and ScriptX objects'
'Codebase' parameters on ALL your documents are 'pointing' to the location
of this new copy of smsx.cab.

  codebase="http://xxxxxxxxxx/smsx.cab#Version=6,1,431,2"

+++++++++++++++++++++++++

As usual, please let me know of any deployment quirks (there should be none)
and we'll try to assist.

Best wishes

Jerry

Mead & Co Limited

++++++++++++++++++++++++
Goodbye to the monocular web.
MeadCo's Zeepe 7 is on release:
http://www.zeepe.com/
++++++++++++++++++++++++