/**
 * @kind path-problem
 */

import java
import semmle.code.java.security.SqlInjectionQuery
import semmle.code.java.dataflow.FlowSources

module SQLInjectionTaintTracking = TaintTracking::Global<QueryInjectionFlowConfig>;
import SQLInjectionTaintTracking::PathGraph

from SQLInjectionTaintTracking::PathNode source, SQLInjectionTaintTracking::PathNode sink
where SQLInjectionTaintTracking::flowPath(source, sink)
select sink, source, sink, "Found SQL injection from $@", source, "source"