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
 
 class XWikiScriptableComponent extends Class {
     XWikiScriptableComponent() {
         this.getAnAnnotation().getType().hasQualifiedName("org.xwiki.component.annotation", "Component") and
         exists(Interface scriptService |
             scriptService.hasQualifiedName("org.xwiki.script.service", "ScriptService") and
             this.extendsOrImplements(scriptService)
         )
     }
 }
 
 // Use the class `XWikiScriptableComponent` and find all the public methods.
 // from XWikiScriptableComponent component, Method publicMethod
 // where component.getAMethod() = publicMethod and publicMethod.isPublic()
 // select component, publicMethod
 
 // Extends the query to find all the parameters of the just found public methods.
 // from XWikiScriptableComponent component, Method publicMethod, Parameter anyParameter
 // where component.getAMethod() = publicMethod and publicMethod.isPublic() and
 //     anyParameter = publicMethod.getAParameter()
 // select component, publicMethod, anyParameter
 
 // Transform the `select` clause into the  class `XWikiScriptableComponentSource` that extends the class `RemoteFlowSource` and identifies parameters of the public methods defined in a scriptable component as sources of untrusted data.
 import semmle.code.java.dataflow.FlowSources
 
 class XWikiScriptableComponentSource extends RemoteFlowSource {
     XWikiScriptableComponentSource() {
         exists(XWikiScriptableComponent component, Method publicMethod, Parameter anyParameter |
             component.getAMethod() = publicMethod and publicMethod.isPublic() and
             anyParameter = publicMethod.getAParameter() and
             this.asParameter() = anyParameter
         )
     }
     
     override string getSourceType() {
         result = "XWiki scriptable component"
     }
 }
 
 // select any(XWikiScriptableComponentSource source)
 
 import QueryInjectionFlow::PathGraph
 
 from QueryInjectionFlow::PathNode source, QueryInjectionFlow::PathNode sink
 where QueryInjectionFlow::flowPath(source, sink)
 select sink, source, sink, "Found SQL injection from $@", source, "source"