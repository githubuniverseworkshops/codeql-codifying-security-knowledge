<h1 align="center">Codifying security knowledge</h1>
<h3 align="center">Going from security advisory to CodeQL query</h3>
<h5 align="center">@thezefan, @lcartey, @rvermeulen</h3>

<p align="center">
  <a href="#mega-prerequisites">Prerequisites</a> •  
  <a href="#books-resources">Resources</a> •
  <a href="#learning-objectives">Learning Objectives</a>
</p>

> Please provide a description of your workshop.

- **Who is this for**: Security Engineers, Security Researchers, Developers.
- **What you'll learn**: Learn how to use CodeQL for code exploration and for finding security issues.
- **What you'll build**: Build a CodeQL query based on a security advisory to find a SQL injection.

## Learning Objectives

In this workshop, you will:

- Learn how to use CodeQL to explore a code base.
- Learn how to use CodeQL to codify security knowledge and find a SQL injection issue.
- Learn how to reuse codified security knowledge to find variants or new security issues.

## :mega: Prerequisites

Before joining the workshop, there are a few items that you will need to install or bring with you.

- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension](https://marketplace.visualstudio.com/items?itemName=github.vscode-codeql).
- Install the required CodeQL pack dependencies by running the command `CodeQL: Install pack dependencies` to install the dependencies for the pack `githubuniverseworkshop/sql-injection-queries`.
- Install [git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/installing-git-large-file-storage) to download the prepared databases or build the databases locally using the provide Make file. The Makefile requires the presence of [Docker](https://www.docker.com/).

## :books: Resources

- [CodeQL documentation](https://codeql.github.com/docs/)
- [SQL injection](https://portswigger.net/web-security/sql-injection)
- [QL language reference](https://codeql.github.com/docs/ql-language-reference/)
- [CodeQL library for Java](https://codeql.github.com/codeql-standard-libraries/java/)

## Workshop

Welcome to the workshop Codifying security knowledge - Going from security advisory to CodeQL query!
In this workshop we will apply CodeQL to gain a better understanding of a security issues reported in a security advisory, codify this new security knowledge so we can
find the security issue, and learn how this codified knowledge can help find variants and other security issues.

Before we get started it is important that all of the prerequisites are met so you participate in the workshop.

The workshop is divided into multiple sections and each section has a corresponding checkpoint (see `java/sql-injection/src/checkpoints`) that you can use to resume from if you were unable to complete the previous section.

### The known security vulnerability

In this workshop we will look for a known _SQL injection vulnerabilities_ in the [XWiki Platform](https://xwiki.org)'s ratings API component. Such vulnerabilities can occur in applications when information that is controlled by a user makes its way to application code that insecurely construct a SQL query and executes it. SQL queries insecurely constructed from user input can be rewritten to perform unintended actions such as the disclosure of sensitive information.

The SQL injection discussed in this workshop is reviewed in [GHSA-79rg-7mv3-jrr5](https://github.com/advisories/GHSA-79rg-7mv3-jrr5) in [GitHub Advisory Database](https://github.com/advisories).

To find the SQL injection we are going to:

- Identify the vulnerable method discussed in the advisory and determine how it is used.
- Model the vulnerable method as a SQL sink so the SQL injection query is aware of this method.
- Identify how the vulnerable method can be used by finding new XWiki specific entrypoints.
- Model the new entrypoints as a source of untrusted data that can be used by CodeQL queries.
  
Once we have completed the above steps, we can see whether the models, our codified security knowledge, can uncover variants or possible
other security issues.

### Finding the insecure function

In the security advisory [GHSA-79rg-7mv3-jrr5](https://github.com/advisories/GHSA-79rg-7mv3-jrr5) in [GitHub Advisory Database](https://github.com/advisories) we learn of a [Jira issue](https://jira.xwiki.org/browse/XWIKI-17662) that discusses SQL injection in more detail.

There exists a method `getAverageRating` whose two parameters are directly used to produce a SQL request.
We will use CodeQL to find the method and use the results to better understand how the SQL injection can manifest.

Select the database [xwiki-platform-ratings-api-12.8-db.zip] as the current database by right-clicking on it in the _Explorer_ and executing the command _CodeQL: Set current database_.

1. Find all the methods with the name `getAverageRating`
   - The `java` module provides a class `Method` to reason about methods in a program.
   - The class `Method` provides the member predicates `getName` and `hasName` to reason about the name of a method.
1. Refine the set of results by limiting it to methods named `getAverageRating` where the first parameter is named `fromsql`.
   - The class `Method` provides the member predicate `getParameter` that expects an index to retrieve the corresponding parameter, if any.
   - The class `Parameter` provides the member predicates `getName` and `hasName` to reason about the name of a parameter.

From the results of the query we find that the method `getAverageRating` passes the `fromsql` parameter to a method named `getAverageRatingFromQuery`.

1. Find all the methods with the name `getAverageRatingFromQuery`.
1. Reduce the number of results by filtering uninteresting results.
   - For example, only consider methods that have a body.

One of the methods uses the `fromsql` parameter to construct a SQL query.
Let's further explore this method to determine how the SQL injection manifests.

### Identifying and modelling a SQL sink

You can use [CheckPoint1.ql](java/sql-injection/src/checkpoints/CheckPoint1.ql) to continue, if needed.

Now that we have found the location of where the SQL statement is constructed we can determine where it is used.

Following the use of `sql`, we can see it is passed to a method `search`.

1. Find all the calls to a method named `search`.
   - Calls to methods are method accesses. The class `MethodAccess` allows you to reason about method accesses.
   - The class `MethodAccess` provides a member predicate `getMethod` allows you to reason about the method being accessed.
   - The class `MethodAccess` provides the member predicates `getName` and `hasName` to reason about the name of a method.

The method name `search` is very common so the above query provides a lot of results. Too many for manual investigation.
Lets refine the set of results to a more manageable set.

1. Find all the method access in the method `getAverageRatingFromQuery`.
   - The class `MethodAccess` provides the member predicate [getEnclosingCallable](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Expr.qll/predicate.Expr$MethodAccess$getEnclosingCallable.0.html) to reason about the method or constructor containing the method access.
   - The class [Callable](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/type.Member$Callable.html) provides the member predicates [getName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Element.qll/predicate.Element$Element$getName.0.html) and [hasName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Element.qll/predicate.Element$Element$hasName.1.html) to reason about the name of a method.

In the context of data flow analysis, a _sink_ refers to a point in the code where data can be used.
If that use happens in a security sensitive context and the data is from an untrusted source the use can introduce a vulnerability.

Now that we have found the sink we want to uniquely identify it.
In Java we can use an element's qualified name, so let use CodeQL to find it for the method `search`.

1. Select the qualified name of the method `search`.
   - The class [Method](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/type.Member$Method.html) provides the member predicate [getQualifiedName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/predicate.Member$Member$getQualifiedName.0.html) useful fore debugging. The more efficient [hasQualifiedName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/predicate.Member$Member$hasQualifiedName.3.html) for restricting a method.

By now our `from..select` statement is starting to grow more complex with the multiple conditions to find the `search` method.
If we continue with this `from..select` statement our query becomes a complex mess that is also hard to read.
Therefore we are going to encapsulate our current logic and give it a name so we can use it.

In QL we have two options for encapsulating logic, a `predicate` or a `class`. Both approaches are semantically equivalent, however a class has some benefits. It doesn't clobber the `where` part of our query. Additionally, you can create subclasses and combine the results with behavior through member predicates to make it easier to work with. With easier we mean it is more discoverable through autocompletion and you can chain multiple member predicate invocations for more succinct queries.
Therefore we are going to transform our `from..select` statement into a `class`.

The process of transforming a `from..select` statement into a class is very mechanical through the following steps:

1. [Define a class](https://codeql.github.com/docs/ql-language-reference/types/#defining-a-class) and it's [characteristic predicate](https://codeql.github.com/docs/ql-language-reference/types/#characteristic-predicates). It will extend, through `extends`, from the class used in the `from` part of your  [select clause](https://codeql.github.com/docs/ql-language-reference/queries/#select-clauses).
1. Copy the `where` part from the [select clause](https://codeql.github.com/docs/ql-language-reference/queries/#select-clauses) into the [characteristic predicate](https://codeql.github.com/docs/ql-language-reference/types/#characteristic-predicates).
1. Replace the variable with type the class `extends` from with the `this` variable.
1. If the class relies on other variables from the `from` part then you can wrap the body of the characteristic predicate with an [exists](https://codeql.github.com/docs/ql-language-reference/formulas/#exists) quantifier to introduce those variable.

Let's demonstrate this with an example.

We start with a select clause.

```ql
import java

from IfStmt ifStmt
where ifStmt.getThen().(BlockStmt).getNumStmt() = 0
select ifStmt, "Empty if statement"
```

We create a class `EmptyIfStmt` that extends from the class `IfStmt` used in the `from` part of our _select clause_ and we copy the `where` part of our _select clause_.

```ql
import java

class EmptyIfStmt extends IfStmt {
    EmptyIfStmt() {
        ifStmt.getThen().(BlockStmt).getNumStmt() = 0
    }
}

from IfStmt ifStmt
where ifStmt.getThen().(BlockStmt).getNumStmt() = 0
select ifStmt, "Empty if statement"
```

Finally, we correct the _characteristic predicate_ by replacing the `ifStmt` variable from our `from` part with the `this` variable.

```ql
import java

class EmptyIfStmt extends IfStmt {
    EmptyIfStmt() {
        this.getThen().(BlockStmt).getNumStmt() = 0
    }
}

from EmptyIfStmt ifStmt
select ifStmt, "Empty if statement"
```

Now lets apply this to our current _select clause_.

1. Create a class `XWikiSearchMethod` that represents the method `com.xpn.xwiki.store.XWikiStoreInterface.search`.

With our new class `XWikiSearchMethod` we can define the _sink_, the location in the program that when reached by untrusted data, results in a SQL injection issue.

When we perform global data flow analysis we need to restrict the location used in the program to make it feasible to perform the analysis. In other words, it is too expensive to perform global data flow analysis for all the variables in the program.
In CodeQL we use a data flow configuration to define such a restriction. The basic ingredients for a configuration are the _source_, the locations we start the analysis, and the _sinks_ where we stop analysis if reached.
The CodeQL language guide for Java provide the section [Analyzing data flow in Java](https://codeql.github.com/docs/codeql-language-guides/analyzing-data-flow-in-java/) to provide in-depth explanation of data flow.

In this workflow we are going to reuse an existing configuration for SQL injection issues so we can focus on defining the _source_ and _sink_.

The module `semmle.code.java.security.SqlInjectionQuery` defines the module `QueryInjectionFlowConfig` that defines a configuration for finding SQL injections. Additionally it provides the [abstract class](https://codeql.github.com/docs/ql-language-reference/types/#abstract-classes) `QueryInjectionSink` to define new query injection sinks. This is possible because unlike regular classes, where subclasses restricts the set of value from it's [domain type](https://codeql.github.com/docs/ql-language-reference/types/#character-types-and-class-domain-types), subclasses of abstract classes expand the set of values represented by the abstract class.

1. Create the class `XWikiSearchSqlInjectionSink` that extends the `QueryInjectionSink` class to mark the first argument of a method access to the method `search`  a _sink_.
   - The `QueryInjectionSink` is a subclass of `DataFlow::Node`, so it represents a node in the dataflow graph.
     You can use the member predicate `asExpr` to find a corresponding AST node.
   - The class `Method` has a member predicate `getAReference`, that is inherited by our class `XWikiSearchMethod`, that provides all the method accesses targeting that method.
   - The class `MethodAccess` has a member predicate `getArgument()` that provided an index returns the nth argument provided to the method access.

### Attack surface and sources

You can copy [CheckPoint2.ql](java/sql-injection/src/checkpoints/CheckPoint2.ql) to continue.

Now that we have our _sink_ defined we can actually run the following query using the SQL injection configuration to see if we are able to find the SQL injection.

```ql
/**
* @kind path-problem
*/
import java
import semmle.code.java.security.SqlInjectionQuery

module SQLInjectionTaintTracking = TaintTracking::Global<QueryInjectionFlowConfig>;
import SQLInjectionTaintTracking::PathGraph

class XWikiSearchMethod extends Method {
    XWikiSearchMethod() {
        this.hasQualifiedName("com.xpn.xwiki.store","XWikiStoreInterface","search")
    }
}

class XWikiSearchSqlInjectionSink extends QueryInjectionSink {
    XWikiSearchSqlInjectionSink() {
        any(XWikiSearchMethod m).getAReference().getArgument(0) = this.asExpr()
    }
}

from SQLInjectionTaintTracking::PathNode source, SQLInjectionTaintTracking::PathNode sink
where SQLInjectionTaintTracking::flowPath(source, sink)
select sink, source, sink, "Found SQL injection from $@", source, "source"
```

This query will return no results because the data flow analysis is unable to find a _path_ from a _source_ of untrusted data to a _sink_.

To better understand our current attack surface, the entrypoints of the application that receives untrusted data, we can make use of existing codified knowledge and run the query.

```ql
import java
import semmle.code.java.dataflow.FlowSources

from RemoteFlowSource source
select source
```

Similar to the `QueryInjectionSink` we have seen in the previous section, the class `RemoteFlowSource` is an abstract class that captures the _concept_ of program location through which untrusted data can enter the program.
The standard library provides an ever growing set of such remote flow sources for open-source frameworks, but it is not complete.

The next step is to determine the entrypoints for the XWiki ratings API.
To get an idea, start with implementing the following query.

1. Find all the method accesses of the method `search`.
   - You can reuse your class `XWikiSearchMethod`.
   - The class `Method` provides the member predicate `getAReference`, that is inherited by our class `XWikiSearchMethod`, providing all the method access of the method.

The results show a singular result in the known method `getAverageRatingFromQuery`.
This method is part of the abstract Java class called `AbstractRatingsManager`.
Since this is an abstract class it is probably extended by other classes and those classes might provide a clue on how the API is used.

1. Find all the classes that extend the abstract class `AbstractRatingsManager`.
   - The class `Class` represent all the classes in the program.
   - The class `Class` provides the member predicates `getName` and `hasName` to reason about the name of a class.
   - The class `Class` provides the member predicate `extendsOrImplements`  that holds if the provide type is an immediate super-type part of the `extends` or `implements` relationship.
  
The query provides a handful of results that we can analyze. After staring a the surrounding code for a bit we start to notice that the class extending the class `AbstractRatingsManager` are annotated with `@Component` and that warrants some further [investigation](https://www.google.com/search?q=XWIKI+component).

It turns out that the XWiki platform can be extended with [components](https://www.xwiki.org/xwiki/bin/view/Documentation/DevGuide/Tutorials/WritingComponents/) and that a component can be [accessed from a wiki page](https://www.xwiki.org/xwiki/bin/view/Documentation/DevGuide/Tutorials/WritingComponents/#HFromwikipages) by writing a `ScriptService` implementation.

Let's focus on these components, because those seem like interesting entrypoints.

1. Write a query that finds classes annotated with `org.xwiki.component.annotation.Component` and implement the interface `org.xwiki.script.service.ScriptService`.
   - The class `Interface` represents all the Java interfaces in a program.
   - The class `Interface` provides the member predicates `getQualifedName` and `hasQualifiedName` to reason about the qualified name of an Java interface.
   - The class `Class` provides the member predicate `getAnAnnotation` to get the annotation that apply to the class.
   - User defined annotations are declared using an [annotation type](https://docs.oracle.com/javase/tutorial/java/annotations/declaring.html). The class `Annotation`, returned by `getAnAnnotation`, provides the member predicate `getType` to get the annotation type of an annotation.
   - The type `AnnotationType` is a specialization of an interface and allows us, among others, to reason about it's qualified name using the member predicates `getQualifiedName` and `hasQualifiedName`.

We again arrived a _select clause_ that has increased in complexity to describe a scriptable component, so it is a good time to encapsulate this knowledge and give it a name.

1. Apply the same mechanical transformation process we used to turn our _select clause_ into the class `XWikiSearchMethod` to create a class `XWikiScriptableComponent`.
   - In this instance we have an extra variable in our `from` part. To introduce temporary variables we can use the `exists` qualifier as follows

     ```ql
     ...
     exists(Interface scriptService |
      ... // use of scriptService
     )
     ```

With the scriptable components identified, we can finally describe a new kind of source.
Any _public method_ on a scriptable components is accessible from a wikipage.
Therefore, we cannot trust the values provide by the parameters of those methods and need to make sure they are properly scrutinized before use in a security sensitive context.

1. Write a class `XWikiScriptableComponentSource` that extends the class `RemoteFlowSource` and identifies parameters of the public methods defined in a scriptable component as sources of untrusted data.
   - Reuse the class `XWikiScriptableComponentSource`, a subclass of `Class`, to reason about scriptable components.
   - The class `Class` provides the member predicate `getAMethod` to get the Java methods that belong to a java class.
   - The class `Method` provides the member predicate `isPublic` to determine if a method is publicly accessible.
   - The class `Method` provides the member predicates `getParameter` and `getAParameter` to reason about parameters associated with a Java method.
   - Subclasses of `RemoteFlowSource` require the implementation of a member predicate `getSourceType` to describe the type of the source.
     Use the following implementation:

     ```ql
      override string getSourceType() {
         result = "XWiki scriptable component
      }
     ```

With our new _source_ we can rerun the SQL injection query to see if we can find the SQL injection reported in the security advisory.
Make sure to add the query meta data key `@kind path-problem` to make use of the path view in the CodeQL Query Result view.

### Variant analysis

With our fresh query we can now look if our freshly codified security knowledge can find variants.
Select the database [xwiki-platform-12.8-db.zip](xwiki-platform-12.8-db.zip) as the current database and re-run the query.
To get a good sense of the newly found variants, comment out the definition of the `XWikiScriptableComponentSource` and compare the differences in results.
