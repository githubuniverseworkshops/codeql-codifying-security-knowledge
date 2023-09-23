import java

// Find all methods calls, named method accesses, named search
// from MethodAccess ma
// where ma.getMethod().hasName("search")
// select ma

// Find the fully qualified name of declaring type of the method search
// from MethodAccess ma, Method m
// where ma.getMethod() = m and 
// m.hasName("search")
// select ma, m.getDeclaringType().getQualifiedName()

// Abstract the above query into a class
class XWikiSearchMethod extends Method {
    XWikiSearchMethod() {
        this.hasName("search")
        and this.getDeclaringType().getQualifiedName() in ["com.xpn.xwiki.XWiki", "com.xpn.xwiki.store.XWikiStoreInterface"]
    }
}

// Find all method calls to XWiki search
// from XWikiSearchMethod m
// select m, m.getAReference()

// Import the SQL injection data flow configuration and extensions points.
import semmle.code.java.security.SqlInjectionQuery

class XWikiSearchSqlInjectionSink extends QueryInjectionSink {
    XWikiSearchSqlInjectionSink() {
        any(XWikiSearchMethod m).getAReference().getArgument(0) =  this.asExpr()
    }
}

from QueryInjectionSink sink
select sink