import java

// First find all the methods
// from Method m
// select m

// Find all the methods named getAverageRating
// from Method m
// where m.hasName("getAverageRating")
// select m

// Find all the methods named getAverageRating and where the first parameters is name fromSql
// from Method m
// where m.hasName("getAverageRating") and m.getParameter(0).hasName("fromsql")
// select m

// Find all the methods named getAverageRatingFromQuery
// from Method m
// where m.hasName("getAverageRatingFromQuery")
// select m

// Find all the methods named getAverageRatingFromQuery with a definition
// from Method m
// where m.hasName("getAverageRatingFromQuery") and
//     exists(m.getBody())
// select m

// Find all methods calls, named method accesses, named search
// from MethodAccess ma
// where ma.getMethod().hasName("search")
// select ma

// Find the fully qualified name of declaring type of the method search that is called in `getAverageRatingFromQuery`
// from MethodAccess ma, Method m
// where ma.getMethod() = m and 
//     m.hasName("search") and
//     ma.getEnclosingCallable().hasName("getAverageRatingFromQuery")
// select ma, m.getQualifiedName()

// Abstract the above query into a class
class XWikiSearchMethod extends Method {
    XWikiSearchMethod() {
        this.hasQualifiedName("com.xpn.xwiki.store","XWikiStoreInterface","search")
    }
}

// Find the first argument of all the invocations of the method search
// from XWikiSearchMethod searchMethod, MethodAccess searchMethodInvocation, Expr firstArg
// where searchMethod.getAReference() = searchMethodInvocation and
//    searchMethodInvocation.getArgument(0) = firstArg
// select searchMethodInvocation, firstArg

// Import the SQL injection data flow configuration and extensions points.
import semmle.code.java.security.SqlInjectionQuery

class XWikiSearchSqlInjectionSink extends QueryInjectionSink {
    XWikiSearchSqlInjectionSink() {
        any(XWikiSearchMethod m).getAReference().getArgument(0) = this.asExpr()
    }
}

from QueryInjectionSink sink
select sink