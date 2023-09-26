import java

// Find all methods calls, named method accesses, named search
// from MethodAccess ma
// where ma.getMethod().hasName("search")
// select ma

// Find the fully qualified name of declaring type of the method search that is called in `getAverageRatingFromQuery`
// from MethodAccess ma, Method m
// where ma.getMethod() = m and 
// m.hasName("search") and
// ma.getEnclosingCallable().hasName("getAverageRatingFromQuery")
// select ma, m.getQualifiedName()

// Abstract the above query into a class
class XWikiSearchMethod extends Method {
    XWikiSearchMethod() {
        this.hasQualifiedName("com.xpn.xwiki.store","XWikiStoreInterface","search")
    }
}

// Find all method calls to XWiki search
// from XWikiSearchMethod m
// select m, m.getAReference()

// Import the SQL injection data flow configuration and extensions points.
import semmle.code.java.security.SqlInjectionQuery

class XWikiSearchSqlInjectionSink extends QueryInjectionSink {
    XWikiSearchSqlInjectionSink() {
        any(XWikiSearchMethod m).getAPossibleImplementation().getParameter(0) = this.asParameter()
    }
}

from QueryInjectionSink sink
select sink