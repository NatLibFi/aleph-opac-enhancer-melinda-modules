#
# Copyright 2008-2010, 2018 University Of Helsinki (The National Library Of Finland)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use strict;

return sub {
 my ($apache_ref, $www_server_ref, $request_attrs_ref, $headers_ref, $content_ref, $datalen, $config_ref) = @_;
 my $lng = find_language($$content_ref);

 translate($content_ref, $config_ref->{'global'}) if ($config_ref->{'global'});
 translate($content_ref, $config_ref->{$lng}) if ($config_ref->{$lng});

 sub find_language($)
 {
   my ($data) = @_;

   my ($lng) = $data =~ /<--\s*LANGUAGE=(\w{3})\s*-->/;

   ($lng) = $data =~ /www\_f\_(\w{3})/ if (!$lng);

   return $lng || 'eng';
 }

 sub translate($$)
 {
   my ($data_ref, $translation_file) = @_;

   my $fh;
   if (!open($fh, "<$translation_file"))
   {
     error("Could not open translation file $translation_file: $!");
     return;
   }

   debuglog("Translating using $translation_file");

   my $lineno = 0;
   while (my $line = <$fh>)
   {
     ++$lineno;

     chomp($line);
     next if (!$line || $line eq '﻿' || substr($line, 0, 1) eq '!');

     if (substr($line, 0, 3) eq 're:')
     {
       my $regexp = '$$data_ref =~ ' . substr($line, 3);
       eval($regexp);
       error("$translation_file ($lineno) while evaluating '$regexp': $@") if ($@);
     }
     else
     {
       my $sep_pos = index($line, ' -- ');
       if ($sep_pos < 0)
       {
         error("$translation_file ($lineno): separator ' -- ' not found on line: '$line'");
       }
       else
       {
         my $src = substr($line, 0, $sep_pos);
         my $dst = substr($line, $sep_pos + 4);
         my $pos = index($$data_ref, $src);
         while ($pos >= 0)
         {
           $$data_ref = substr($$data_ref, 0, $pos) . $dst . substr($$data_ref, $pos + length($src));
           $pos = index($$data_ref, $src, $pos + length($dst));
         }
       }
     }
   }
   close($fh);
 }
};
