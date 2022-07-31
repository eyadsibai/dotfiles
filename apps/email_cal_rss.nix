{ pkgs, ... }: {

  home.packages = with pkgs; [
    khal
    calcurse # A calendar and scheduling application for the command line
    gcalcli
    # goobook
  ];
  programs.himalaya = { enable = true; };

  programs.neomutt = { enable = true; };

  # TODO https://github.com/LukeSmithxyz/voidrice/blob/master/.config/newsboat/config
  programs.newsboat = {
    enable = true;
    autoReload = true;
    extraConfig = ''
      feed-sort-order unreadarticlecount-asc
      show-read-feeds no
      show-read-articles  no
      # solarized
      color background         default   default
      color listnormal         default   default
      color listnormal_unread  default   default
      color listfocus          black     cyan
      color listfocus_unread   black     cyan
      color info               default   black
      color article            default   default
    '';

    urls = [

      { url = "https://lukesmith.xyz/rss.xml"; }
      { url = "https://lindypress.net/rss"; }
      { url = "https://notrelated.xyz/rss"; }
      {
        url =
          "https://www.youtube.com/feeds/videos.xml?channel_id=UC2eYFnH61tmytImy1mTYvhA";
        title = "~Luke Smith (YouTube)";
      }
      { url = "https://landchad.net/rss.xml"; }
      { url = "https://based.cooking/index.xml"; }
      {
        url = "https://artixlinux.org/feed.php";
        tags = [ "tech" ];
      }
      {
        url = "https://www.archlinux.org/feeds/news/";
        tags = [ "tech" ];
      }
      { url = "https://nrdxp.dev/feed.xml"; }
      { url = "https://initialcommit.com/blog/rss.xml"; }
      { url = "https://ww.telent.net/news.rss"; }
      { url = "https://guix.gnu.org/feeds/blog.atom"; }
      { url = "https://blog.servo.org/feed.xml"; }
      { url = "https://www.radicalroutes.org.uk/?format=feed&type=atom"; }
      { url = "https://matklad.github.io/feed.xml"; }
      { url = "https://sfconservancy.org/feeds/blog/"; }
      { url = "https://sourcehut.org/blog/index.xml"; }
      {
        url =
          "https://openwrt.org/feed.php?type=rss&mode=list&sort=date&ns=advisory&linkto=current&content=html";
      }
      { url = "https://nora.codes/index.xml"; }
      { url = "http://hackedfrompieces.wordpress.com/feed/"; }
      { url = "http://notonlyzeroesandones.site40.net/feed/"; }
      { url = "https://tonyarcieri.com/feed"; }
      { url = "https://www.destroyallsoftware.com/screencasts/feed"; }
      { url = "https://blog.liftsecurity.io/rss"; }
      { url = "http://mightyohm.com/blog/feed/"; }
      { url = "http://feeds.falkvinge.net/Falkvinge-on-Infopolicy"; }
      { url = "http://www.veronicabelmont.com/feed/"; }
      { url = "https://perplexinglyemma.blogspot.com/feeds/posts/default"; }
      { url = "http://mobiwroclaw.nazwa.pl/rsschannel/channels/Wszystkie.xml"; }
      { url = "http://www.davecooper.org/blog/feed/"; }
      { url = "http://hackaweek.com/hacks/?feed=rss2"; }
      { url = "https://www.hadean.com/blog/rss.xml"; }
      { url = "http://feeds.feedburner.com/malukah"; }
      { url = "http://jonasdn.blogspot.com/feeds/posts/default"; }
      { url = "https://www.destroyallsoftware.com/blog/index.xml"; }
      { url = "http://metajack.im/"; }
      { url = "https://haskell-at-work.com/feed.xml"; }
      { url = "http://kingdomcomerpg.com/?feed=rss2"; }
      { url = "http://temporal.pr0.pl/devblog/feed/"; }
      { url = "https://ohm2013.org/site/feed/"; }
      { url = "http://www.wroclaw.pl/rss.xml"; }
      { url = "https://superevr.com/blog/feed/"; }
      { url = "http://thejoysofcode.com/rss"; }
      { url = "http://www.rsspect.com/rss/threeps.xml"; }
      { url = "http://brianzawesomeblog.blogspot.com/feeds/posts/default"; }
      { url = "http://ssj3gohan.tweakblogs.net/feed/"; }
      { url = "http://planet.mozilla.org/releng/atom.xml"; }
      { url = "https://grahamc.com/feed/"; }
      { url = "http://www.h-online.com/grand-atom.xml"; }
      { url = "https://jneem.github.io/feed.xml"; }
      { url = "http://blog.opensourceecology.org/feed/"; }
      { url = "http://pepijndevos.nl/atom.xml"; }
      { url = "https://wedistribute.org/feed/"; }
      { url = "http://www.wattnotions.com/feed/"; }
      { url = "https://blondihacks.com/feed/"; }
      { url = "http://ghcarm.wordpress.com/feed/"; }
      { url = "http://blog.tkjelectronics.dk/feed/"; }
      { url = "https://www.circuitlab.com/blog/feed/"; }
      { url = "http://danluu.com/atom.xml"; }
      { url = "http://silverwingedseraph.net/feed"; }
      { url = "http://takbardzozle.blogspot.com/feeds/posts/default"; }
      { url = "https://weekly.nixos.org/feeds/all.rss.xml"; }
      { url = "http://www.hscott.net/feed/"; }
      { url = "http://feeds.feedburner.com/kernelmag?format=xml"; }
      { url = "http://www.malwaretech.com/feeds/posts/default"; }
      { url = "https://nixos.org/blogs.xml"; }
      { url = "http://this8bitlife.com/feed/"; }
      { url = "http://spaceismore.com/feed/"; }
      { url = "https://blog.cyplo.dev/index.xml"; }
      { url = "https://blog.kobol.io/feed.xml"; }
      { url = "http://blog.ffwll.ch/feeds/posts/default"; }
      { url = "http://blog.pnkfx.org/atom.xml"; }
      { url = "http://metaltronics.wordpress.com/feed/"; }
      {
        url =
          "https://github.com/Infusion-Open-Source/gaming-competition-platform/commits/networking.atom";
      }
      { url = "http://ncrmnt.org/wp/feed/"; }
      { url = "http://www.arachnidlabs.com/atom.xml"; }
      { url = "http://blogs.valvesoftware.com/feed/"; }
      { url = "http://billmccloskey.wordpress.com/feed/"; }
      { url = "http://blog.ncrunch.net/syndication.axd"; }
      { url = "http://sparkleshare.org/feed/"; }
      { url = "http://osprintingllc.com/feed/"; }
      {
        url =
          "https://forum.openwrt.org/extern.php?action=feed&fid=11&type=rss";
      }
      { url = "http://corgibytes.com/feed.xml"; }
      { url = "http://chatolandia.pl/feed/"; }
      { url = "http://niczsoft.com/feed/"; }
      { url = "http://blog.macrofab.net/feed/"; }
      { url = "http://hackaday.com/feed/"; }
      { url = "https://blog.uncensoreddns.org/feeds/atom/all/"; }
      { url = "http://www.paulallenengineering.com/1/feed"; }
      {
        url =
          "http://komornik.wroclaw.pl/index.php?option=com_rss&feed=RSS2.0&no_html=1";
      }
      { url = "https://rachelbythebay.com/w/atom.xml"; }
      { url = "http://sliptonic.com/feed/"; }
      { url = "http://blog.unsecu.re/feeds/posts/default"; }
      { url = "http://neverworkintheory.org/feed.xml"; }
      { url = "http://kocikocizabci.blogspot.com/feeds/posts/default"; }
      { url = "https://blog.christophersmart.com/feed/"; }
      { url = "http://sarah.thesharps.us/feed/"; }
      { url = "http://explique.me/feed.xml"; }
      { url = "http://www.arcfn.com/feeds/posts/default"; }
      { url = "http://sunrider-vn.com/feed/"; }
      { url = "http://www.wrocnet.org/syndication.axd"; }
      { url = "http://www.goldsborough.me/feed.xml"; }
      { url = "http://securitynirvana.blogspot.com/feeds/posts/default"; }
      { url = "http://blog.tilaa.nl/feeds/posts/default"; }
      { url = "http://latkin.org/blog/index.xml"; }
      { url = "https://ind.ie/blog/rss/index.xml"; }
      { url = "http://spritesmods.com/rss.php"; }
      { url = "http://codeascraft.etsy.com/feed/"; }
      { url = "http://chrisgammell.com/feed/"; }
      { url = "http://j2kun.svbtle.com/feed"; }
      { url = "https://www.stellar.org/feed/"; }
      { url = "http://shenzhentrip.blogspot.com/feeds/posts/default"; }
      { url = "https://aphyr.com/posts.atom"; }
      { url = "http://www.latentlaboratories.com/blog?format=RSS"; }
      { url = "http://zentasrobots.com/feed/"; }
      { url = "http://tuxdiary.com/feed/"; }
      { url = "http://grugq.github.io/atom.xml"; }
      { url = "http://gusclass.com/blog/feed/"; }
      { url = "http://www.devttys0.com/feed/"; }
      { url = "http://www.lighttable.com/atom.xml"; }
      { url = "https://www.ruma.io/news/feed.atom"; }
      { url = "http://runawaybrainz.blogspot.com/feeds/posts/default"; }
      { url = "http://blog.ploeh.dk/rss.xml"; }
      { url = "http://lab.whitequark.org/atom.xml"; }
      { url = "http://rroarr.blog.pl/index.rss"; }
      { url = "http://slic3r.org/rss"; }
      { url = "http://feeds.feedburner.com/EmbeddedInAcademia"; }
      { url = "http://mightydevices.com/?feed=rss2"; }
      { url = "http://www.cppwroclaw.pl/dokuwiki/feed.php"; }
      { url = "http://pagekite.net/Blog?rss=1"; }
      { url = "http://iradan.com/?feed=rss2"; }
      { url = "http://tirania.org/blog/miguel.rss2"; }
      { url = "http://the-missing-link-of-agile.com/feed/"; }
      { url = "http://www.kroah.com/log/index.rss"; }
      { url = "http://ebldc.com/?feed=rss2"; }
      { url = "http://barwybiedy.blogspot.com/feeds/posts/default"; }
      { url = "http://codegangsta.io/atom.xml"; }
      { url = "http://intorust.com/feed.xml"; }
      { url = "http://feeds.feedburner.com/debugshow"; }
      { url = "http://carol-nichols.com/feed.xml"; }
      { url = "http://blogs.msdn.com/b/ericlippert/atom.aspx"; }
      { url = "http://kroah.com/log/index.rss"; }
      { url = "http://quinndunki.com/blondihacks/?feed=rss2"; }
      { url = "http://gerrysweeney.com/feed/"; }
      { url = "http://cybergibbons.com/feed/"; }
      { url = "https://freedom-to-tinker.com/feed/"; }
      { url = "http://sealedabstract.com/feed/"; }
      { url = "http://hermanradtke.com/atom.xml"; }
      { url = "http://feeds.feedburner.com/plainlystated/xtwL?format=xml"; }
      { url = "http://www.mdswanson.com/atom.xml"; }
      { url = "http://feeds.feedburner.com/thegrue"; }
      { url = "https://gergely.imreh.net/blog/feed/"; }
      { url = "https://freelabpl.wordpress.com/feed/"; }
      { url = "http://www.sigrok.org/blog/rss.xml"; }
      { url = "http://www.sigrok.org/blog/blog/feed"; }
      { url = "https://thesquareplanet.com/feed.xml"; }
      { url = "http://feedpress.me/inessential"; }
      { url = "http://wheningit.tumblr.com/rss"; }
      { url = "http://b.truzzi.me/?feed=rss2"; }
      { url = "https://blog.conformal.com/feed/"; }
      { url = "http://windytan.blogspot.com/feeds/posts/default"; }
      { url = "http://www.logicalelegance.com/journey/feed/"; }
      { url = "https://www.adafruit.com/blog/feed/"; }
      { url = "https://electronichamsters.wordpress.com/feed/"; }
      { url = "http://security.goatse.fr/feed"; }
      { url = "http://panoptykon.org/rss.xml"; }
      { url = "http://blog.piston.rs/atom.xml"; }
      { url = "http://tenderlovemaking.com/atom.xml"; }
      { url = "http://www.sublimetext.com/blog/feed"; }
      { url = "https://kaktuscircuits.blogspot.com/feeds/posts/default"; }
      { url = "http://www.wired.com/threatlevel/feed/"; }
      { url = "http://onethingwell.org/rss"; }
      { url = "http://serialized.net/rss.xml"; }
      { url = "http://aosabook.org/blog/feeds/all.atom.xml"; }
      { url = "http://www.alicegrove.com/rss"; }
      { url = "http://www.konradokonski.com/KWD/feed/"; }
      { url = "http://way-cooler.org/feed.xml"; }
      { url = "http://antygea.blogspot.com/feeds/posts/default"; }
      { url = "http://blog.gameagent.com/feed/"; }
      { url = "http://llogiq.github.io/feed.xml"; }
      { url = "http://lambda-the-ultimate.org/rss.xml"; }
      { url = "https://soldernerd.com/feed/"; }
      { url = "http://www.0xrage.com/?feed=rss2"; }
      { url = "http://www.bitscope.com/blog/feed.xml"; }
      { url = "http://theprofoundprogrammer.com/rss"; }
      { url = "http://essentialscrap.com/rss.xml"; }
      { url = "http://handmade.hackaday.com/feed/"; }
      { url = "http://events.ccc.de/feed/"; }
      { url = "http://www.estechnical.co.uk/blog/latest?format=feed&type=rss"; }
      { url = "http://perso.aquilenet.fr/~sven337/feeds/feed_english.xml"; }
      { url = "http://blog.trailofbits.com/feed/"; }
      { url = "https://michaelwoerister.github.io/feed.xml"; }
      { url = "http://nitschinger.at//index.xml"; }
      { url = "http://lambdaops.com/feed"; }
      { url = "http://simon-says-architecture.com/feed/"; }
      { url = "https://sha2017.org/rss.xml"; }
      { url = "http://blog.bitbucket.org/feed/"; }
      { url = "http://www.davidhunt.ie/feed/"; }
      { url = "https://begriffs.com/atom.xml"; }
      { url = "http://dankaminsky.com/feed/"; }
      { url = "https://www.bios-mods.com/feed/"; }
      { url = "http://www.analogzoo.com/feed/"; }
      { url = "http://blog.makezine.com/feed/"; }
      { url = "http://wot.lv/feeds/all.atom.xml"; }
      { url = "http://www.tridimake.com/feeds/posts/default"; }
      { url = "http://www.bunniestudios.com/blog/?feed=rss2"; }
      { url = "http://feeds.feedburner.com/ElixirLang?format=xml"; }
      { url = "http://lukelectro.wordpress.com/feed/"; }
      { url = "http://buffered.io/index.xml"; }
      { url = "http://anholt.livejournal.com/data/rss"; }
      { url = "http://www.yesodweb.com/feed"; }
      { url = "http://feeds.feedburner.com/arkency.xml"; }
      { url = "https://github.com/blog.atom"; }
      { url = "http://lcamtuf.blogspot.com/feeds/posts/default"; }
      { url = "http://feeds.feedburner.com/schneier/fulltext"; }
      { url = "https://simplysecure.org/feed.xml"; }
      { url = "http://maryrosecook.com/blog/feed"; }
      { url = "https://nathanleclaire.com/index.xml"; }
      { url = "http://downingsbasement.com/feed/"; }
      { url = "http://www.pxdojo.net/feeds/posts/default"; }
      { url = "http://feeds.feedburner.com/GlosyWmojejGlowie"; }
      { url = "http://corenominal.org/feed/"; }
      { url = "http://fulmicoton.com/atom.xml"; }
      { url = "http://mechanical-sympathy.blogspot.com/feeds/posts/default"; }
      { url = "http://rys.io/en/rss"; }
      { url = "https://rust-embedded.github.io/blog/rss.xml"; }
      { url = "https://pointersgonewild.com/feed/"; }
      { url = "http://blog.cryptographyengineering.com/feeds/posts/default"; }
      { url = "http://www.hardhack.org/feed/"; }
      { url = "http://blog.system76.com/rss"; }
      { url = "https://www.mailpile.is/blog/index.rss"; }
      { url = "https://blog.rustfest.eu/feed.xml"; }
      { url = "http://theinvisiblethings.blogspot.com/feeds/posts/default"; }
      { url = "https://spideroak.com/blog/feed"; }
      { url = "http://nullr0ute.com/feed/"; }
      { url = "http://xion.io/feeds/atom.xml"; }
      { url = "http://blog.mozilla.org/nfroyd/feed/"; }
      { url = "http://anniemachon.ch/feed"; }
      { url = "http://befinitiv.wordpress.com/feed/"; }
      {
        url =
          "http://michaelfeathers.typepad.com/michael_feathers_blog/atom.xml";
      }
      { url = "http://www.2600.com/rss.xml"; }
      { url = "http://www.planet-rust.com/atom.xml"; }
      { url = "http://www.elidedbranches.com/feeds/posts/default"; }
      { url = "http://www.eevblog.com/feed/"; }
      { url = "http://blog.chromium.org/feeds/posts/default"; }
      { url = "http://www.questionablecontent.net/QCRSS.xml"; }
      { url = "http://davidegironi.blogspot.com/feeds/posts/default"; }
      { url = "http://intorust.com/blog/feed.xml"; }
      { url = "http://londyn.msz.gov.pl/rss/ambasadalondynaktualnosci.xml450"; }
      { url = "http://www.thegamercat.com/feed/"; }
      { url = "http://feeds.feedburner.com/gadgetfactory/zjHC"; }
      { url = "http://feeds.feedburner.com/Karosium"; }
      { url = "http://embedderslife.wordpress.com/feed/"; }
      { url = "http://kernel.org/kdist/rss.xml"; }
      { url = "https://www.blackhat.com/BlackHatRSS.xml"; }
      { url = "http://blog.ctf365.com/feed/"; }
      { url = "http://bristolcrypto.blogspot.com/feeds/posts/default"; }
      { url = "http://owncloud.org/news/feed/"; }
      { url = "http://jreeblog.wordpress.com/feed/"; }
      { url = "http://www.wildcircuits.com/feeds/posts/default"; }
      { url = "http://www.raspberrypi.org/feed"; }
      { url = "http://feeds.feedburner.com/bartongeorge/nMQw"; }
      { url = "https://apollo.open-resource.org/mission:log:feed"; }
      { url = "http://bikerglen.com/blog/feed/"; }
      { url = "http://www.crypto.com/blog/rss20.xml"; }
      { url = "https://www.platymuus.com/feed.xml"; }
      { url = "http://oneweekwonder.blogspot.com/feeds/posts/default"; }
      { url = "https://revvrysuje.blogspot.com/feeds/posts/default"; }
      { url = "https://blog.mozilla.org/thunderbird/feed/"; }
      { url = "https://blog.mozilla.org/research/feed/"; }
      { url = "http://thesignalpath.com/blogs/feed/"; }
      { url = "http://www.daemonology.net/blog/index.rss"; }
      { url = "http://about.travis-ci.org/blog.xml"; }
      { url = "http://dangerousprototypes.com/feed/"; }
      { url = "https://www.trueos.org/feed/"; }
      { url = "http://nautil.us/rss/all"; }
      { url = "http://blog.computationalcomplexity.org/feeds/posts/default"; }
      { url = "https://github.com/ogham/exa/releases.atom"; }
      { url = "http://blog.humblebundle.com/rss"; }
      { url = "http://blog.reprap.org/feeds/posts/default"; }
      { url = "https://copperhead.co/feed.xml"; }
      { url = "http://blog.xamarin.com/feed/"; }
      { url = "http://coreos.com/atom.xml"; }
      { url = "http://lowpowerlab.com/feed/"; }
      { url = "http://feeds.feedburner.com/technicalblogging"; }
      { url = "http://feeds.feedburner.com/TheBitBangTheory_en?format=xml"; }
      { url = "http://feeds.feedburner.com/TheLifeOfKenneth"; }
      { url = "http://feeds.feedburner.com/WebServices20"; }
      { url = "http://feeds.feedburner.com/zotero/"; }
      { url = "http://corporat.blox.pl/rss2"; }
      { url = "http://feeds.feedburner.com/codinghorror/"; }
      { url = "https://feeds.feedburner.com/ezyang"; }
      { url = "http://www.willowgarage.com/news/feed"; }
      { url = "http://life.hackaday.com/feed/"; }
      { url = "https://stripe.com/blog/feed.rss"; }
      { url = "http://nakedsecurity.sophos.com/feed/"; }
      { url = "https://www.braintreepayments.com/rss"; }
      { url = "http://edri.org/feed/"; }
      {
        url =
          "http://feeds.feedburner.com/GiantRobotsSmashingIntoOtherGiantRobots";
      }
      { url = "http://blog.dnsimple.com/feed.xml"; }
      { url = "http://githubengineering.com/atom.xml"; }
      { url = "https://ruudvanasseldonk.com/feed.xml"; }
      { url = "http://www.lowrisc.org//index.xml"; }
      { url = "http://feeds.feedburner.com/NadBrzegiemBiurkaUsiadamIPakaam"; }
      { url = "http://feeds.feedburner.com/Phoronix"; }
      { url = "http://jvns.ca/atom.xml"; }
      { url = "http://feeds.feedburner.com/37signals/beMH"; }
      { url = "http://feeds.feedburner.com/steveklabnik/words"; }
      { url = "https://blog.torproject.org/blog/feed"; }
      { url = "http://this-week-in-rust.org/atom.xml"; }
      { url = "http://opensource.com/feed"; }
      { url = "http://blog.elementary.io/rss"; }
      { url = "https://www.insinuator.net/feed/"; }
      { url = "https://www.mapbox.com/blog/blog.rss"; }
      { url = "http://www.harmj0y.net/blog/feed/"; }
      { url = "http://codurance.com/atom.xml"; }
      { url = "https://blog.makersacademy.com/feed"; }
      { url = "https://semaphoreci.com/blog/feed.xml"; }
      { url = "https://sensepost.com/rss.xml"; }
      { url = "https://www.evilsocket.net/atom.xml"; }
      { url = "https://krebsonsecurity.com/feed/"; }
      { url = "https://tisiphone.net/feed/"; }
      { url = "https://blog.bastion.rs/feed.xml"; }
    ];
  };
}
