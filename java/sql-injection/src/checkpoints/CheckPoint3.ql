/**
 * @kind path-problem
 */

import java
import semmle.code.java.security.SqlInjectionQuery

class XWikiSearchMethod extends Method {
    XWikiSearchMethod() {
        this.hasQualifiedName("com.xpn.xwiki.store","XWikiStoreInterface","search")
    }
}

class XWikiSearchSqlInjectionSink extends QueryInjectionSink {
    XWikiSearchSqlInjectionSink() {
        any(XWikiSearchMethod m).getAPossibleImplementation().getParameter(0) = this.asParameter()
    }
}

import semmle.code.java.dataflow.FlowSources

module SQLInjectionTaintTracking = TaintTracking::Global<QueryInjectionFlowConfig>;
import SQLInjectionTaintTracking::PathGraph

// Let's test our new sink to see if we can find paths to it.
// from SQLInjectionTaintTracking::PathNode source, SQLInjectionTaintTracking::PathNode sink
// where SQLInjectionTaintTracking::flowPath(source, sink)
// select sink, source, sink, "Found SQL injection from $@", source, "source"

// Let's retrieve all the known sources of untrusted input (make sure to disable the @kind meta data on the query above by prefixing it with //)
// from RemoteFlowSource source
// select source

// Let see who is calling the search method
// from XWikiSearchMethod m
// select m.getAReference()

// The vulnerable method `getAverageRatingFromQuery` is implemented by the abstract class `AbstractRatingsManager`.
// Let's find all the classes that `extend` from it.
// from Class impl
// where impl.getASourceSupertype().hasName("AbstractRatingsManager")
// select impl

// We found 3 classes that `extend` from `AbstractRatingsManager`.
// They all are XWiki Components as gathered from the annotation `org.xwiki.component.annotation.Component`
// A component is accessible from wiki pages if it implements `org.xwiki.script.service.ScriptService` (see https://www.xwiki.org/xwiki/bin/view/Documentation/DevGuide/Tutorials/WritingComponents/#HFromwikipages)
// Let's find all the classes that `implement` `org.xwiki.script.service.ScriptService`
// from Class impl
// where impl.getASourceSupertype().hasQualifiedName("org.xwiki.script.service", "ScriptService") and
//    impl.getAnAnnotation().getType().hasQualifiedName("org.xwiki.component.annotation", "Component")
// select impl

// Let's turn the above from...select into a class so we can reuse it
class ScriptableComponent extends Class {
    ScriptableComponent() {
        this.getASourceSupertype().hasQualifiedName("org.xwiki.script.service", "ScriptService") and
        this.getAnAnnotation().getType().hasQualifiedName("org.xwiki.component.annotation", "Component")
    }
}

// Let's turn all the parameters of a public method on a ScriptableComponent into a source of untrusted input.
class ScriptableComponentSource extends RemoteFlowSource {
    ScriptableComponentSource() {
        exists(ScriptableComponent c, Method m | c.getAMethod() = m and m.isPublic() |
            m.getAParameter() = this.asParameter()
        )
    }

    override string getSourceType() {
        result = "XWiki scriptable component"
    }
}

// Let's test our new source to see if we can find a path to our sink. (Don't forget to re-enable the @kind meta data on the query above)
from SQLInjectionTaintTracking::PathNode source, SQLInjectionTaintTracking::PathNode sink
where SQLInjectionTaintTracking::flowPath(source, sink) //and sink.getNode() instanceof XWikiSearchSqlInjectionSink
select sink, source, sink, "Found SQL injection from $@", source, "source"