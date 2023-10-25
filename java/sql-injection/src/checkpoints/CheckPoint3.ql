/**
* @kind path-problem
*/

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

// Find the search method call and its first argument.
// from Method searchMethod, MethodAccess searchMethodInvocation, Expr firstArg
// where searchMethod.hasQualifiedName("com.xpn.xwiki.store","XWikiStoreInterface","search") and
//     searchMethod = searchMethodInvocation.getMethod() and
//    searchMethodInvocation.getArgument(0) = firstArg
// select searchMethodInvocation, firstArg

// Import the SQL injection data flow configuration and extensions points.
import semmle.code.java.security.SqlInjectionQuery

class XWikiSearchSqlInjectionSink extends QueryInjectionSink {
   XWikiSearchSqlInjectionSink() {
     exists(Method searchMethod, MethodAccess searchMethodInvocation, Expr firstArg |
       searchMethod.hasQualifiedName("com.xpn.xwiki.store", "XWikiStoreInterface", "search") and
       searchMethod = searchMethodInvocation.getMethod() and
       searchMethodInvocation.getArgument(0) = firstArg
     |
       firstArg = this.asExpr()
     )
   }
}

// from QueryInjectionSink sink
// select sink

// Write a query that finds classes annotated with `org.xwiki.component.
// from Class component
// where component.getAnAnnotation().getType().hasQualifiedName("org.xwiki.component.annotation", "Component")
// select component

// Extend the query to include only classes that implement the interface `org.xwiki.script.service.ScriptService`.
// from Class component, Interface scriptService
// where component.getAnAnnotation().getType().hasQualifiedName("org.xwiki.component.annotation", "Component") and
//     scriptService.hasQualifiedName("org.xwiki.script.service", "ScriptService") and
//     component.extendsOrImplements(scriptService)
// select component

// Extend the query to find all the public methods of a component.
// from Class component, Interface scriptService, Method publicMethod
// where component.getAnAnnotation().getType().hasQualifiedName("org.xwiki.component.annotation", "Component") and
//     scriptService.hasQualifiedName("org.xwiki.script.service", "ScriptService") and
//     component.extendsOrImplements(scriptService) and
//     component.getAMethod() = publicMethod and publicMethod.isPublic()
// select component, publicMethod

// Extends the query to find all the parameters of the just found public methods.
// from Class component, Interface scriptService, Method publicMethod, Parameter parameter
// where component.getAnAnnotation().getType().hasQualifiedName("org.xwiki.component.annotation", "Component") and
//     scriptService.hasQualifiedName("org.xwiki.script.service", "ScriptService") and
//     component.extendsOrImplements(scriptService) and
//     component.getAMethod() = publicMethod and publicMethod.isPublic() and
//     publicMethod.getAParameter() = parameter
// select component, publicMethod, parameter

class XWikiScriptableComponentSource extends RemoteFlowSource {
   XWikiScriptableComponentSource() {
       exists(Class component, Interface scriptService, Method publicMethod, Parameter parameter |
           component
               .getAnAnnotation()
               .getType()
               .hasQualifiedName("org.xwiki.component.annotation", "Component") and
           scriptService.hasQualifiedName("org.xwiki.script.service", "ScriptService") and
           component.extendsOrImplements(scriptService) and
           component.getAMethod() = publicMethod and
           publicMethod.isPublic() and
           publicMethod.getAParameter() = parameter
           |
           this.asParameter() = parameter
       )
   }

   override string getSourceType() { result = "XWiki scriptable component" }
}

import QueryInjectionFlow::PathGraph

from QueryInjectionFlow::PathNode source, QueryInjectionFlow::PathNode sink
where QueryInjectionFlow::flowPath(source, sink)
select sink, source, sink, "Found SQL injection from $@", source, "source"