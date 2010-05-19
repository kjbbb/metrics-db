package org.torproject.ernie.web;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import java.util.*;

public class NewUsersGraphsServlet extends HttpServlet {

  public void doGet(HttpServletRequest request,
      HttpServletResponse response) throws IOException,
      ServletException {

    PrintWriter out = response.getWriter();
    out.print("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n"
        + "<html>\n"
        + "  <head>\n"
        + "    <title>Tor Metrics Portal: New or returning, directly connecting Tor users</title>\n"
        + "    <meta http-equiv=Content-Type content=\"text/html; charset=iso-8859-1\">\n"
        + "    <link href=\"http://www.torproject.org/stylesheet-ltr.css\" type=text/css rel=stylesheet>\n"
        + "    <link href=\"http://www.torproject.org/favicon.ico\" type=image/x-icon rel=\"shortcut icon\">\n"
        + "  </head>\n"
        + "  <body>\n"
        + "    <div class=\"center\">\n"
        + "      <table class=\"banner\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" summary=\"\">\n"
        + "        <tr>\n"
        + "          <td class=\"banner-left\"><a href=\"https://www.torproject.org/\"><img src=\"http://www.torproject.org/images/top-left.png\" alt=\"Click to go to home page\" width=\"193\" height=\"79\"></a></td>\n"
        + "          <td class=\"banner-middle\">\n"
        + "            <a href=\"/\">Home</a>\n"
        + "            <a class=\"current\">Graphs</a>\n"
        + "            <a href=\"papers.html\">Papers</a>\n"
        + "            <a href=\"data.html\">Data</a>\n"
        + "            <a href=\"tools.html\">Tools</a>\n"
        + "          </td>\n"
        + "          <td class=\"banner-right\"></td>\n"
        + "        </tr>\n"
        + "      </table>\n"
        + "      <div class=\"main-column\">\n"
        + "        <h2>Tor Metrics Portal: Graphs</h2>\n"
        + "        <br/>\n"
        + "        <h3>New or returning, directly connecting Tor users</h3>\n"
        + "        <br/>\n"
        + "        <p>Users connecting to the Tor network for the first time request\n"
        + "        a list of running relays from one of currently seven directory\n"
        + "        authorities. Likewise, returning users whose network information is\n"
        + "        out of date connect to one of the directory authorities to\n"
        + "        download a fresh list of relays. The following graphs display an\n"
        + "        estimate of new or returning Tor users based on the requests as\n"
        + "        seen by gabelmoo, one of the directory authorities.</p>\n"
        + "        <ul>\n"
        + "          <li><a href=\"#bahrain\">Bahrain</a></li>\n"
        + "          <li><a href=\"#china\">China</a></li>\n"
        + "          <li><a href=\"#cuba\">Cuba</a></li>\n"
        + "          <li><a href=\"#ethiopia\">Ethiopia</a></li>\n"
        + "          <li><a href=\"#iran\">Iran</a></li>\n"
        + "          <li><a href=\"#burma\">Burma</a></li>\n"
        + "          <li><a href=\"#saudi\">Saudi</a></li>\n"
        + "          <li><a href=\"#syria\">Syria</a></li>\n"
        + "          <li><a href=\"#tunisia\">Tunisia</a></li>\n"
        + "          <li><a href=\"#turkmenistan\">Turkmenistan</a></li>\n"
        + "          <li><a href=\"#uzbekistan\">Uzbekistan</a></li>\n"
        + "          <li><a href=\"#vietnam\">Vietnam</a></li>\n"
        + "          <li><a href=\"#yemen\">Yemen</a></li>\n"
        + "        </ul>\n"
        + "        <ul>\n"
        + "          <li><a href=\"csv/new-users.csv\">CSV</a> file containing all\n"
        + "            data.</li>\n"
        + "        </ul>\n"
        + "        ");
    List<String> countries = Arrays.asList((
        "bahrain,china,cuba,ethiopia,iran,burma,saudi,syria,tunisia,"
        + "turkmenistan,uzbekistan,vietnam,yemen").split(","));
    List<String> suffixes = new ArrayList<String>(Arrays.asList(
        "30d,90d,180d,all".split(",")));
    Calendar now = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
    suffixes.add(String.format("%tY", now));
    suffixes.add(String.format("%1$tY-q%2$d", now,
        1 + now.get(Calendar.MONTH) / 3));
    suffixes.add(String.format("%1$tY-%1$tm", now));
    for (String country : countries) {
      out.print("<p><a id=\"" + country + "\"/>\n");
      for (String suffix : suffixes) {
        out.print("        <img src=\"graphs/new-users/" + country
            + "-new-" + suffix + ".png\"/>\n");
      }
      out.print("        </p>");
    }
    out.print("<br/>\n"
        + "      </div>\n"
        + "    </div>\n"
        + "    <div class=\"bottom\" id=\"bottom\">\n"
        + "      <p>\"Tor\" and the \"Onion Logo\" are <a href=\"https://www.torproject.org/trademark-faq.html.en\">registered trademarks</a> of The Tor Project, Inc.</p>\n"
        + "    </div>\n"
        + "  </body>\n"
        + "</html>\n");
    out.close();
  }
}
