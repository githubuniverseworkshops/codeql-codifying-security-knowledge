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
In this workshop we will apply CodeQL to gain a better understanding of a security issues reported in a security advisory, codify this new security knowledge, and run it to find a SQL injection issue and other variants.

Before we get started it is important that all of the prerequisites are met so you can participate in the workshop.

The workshop is divided into multiple sections and each section consists of exercises that build up to the final query.
For each section we provide _hints_ that help you finish the exercise by providing you with references to QL classes and member predicates that you can use.

### Overview

In this workshop we will look for a known _SQL injection vulnerabilities_ in the [XWiki Platform](https://xwiki.org)'s ratings API component. Such vulnerabilities can occur in applications when information that is controlled by a user makes its way to application code that insecurely construct a SQL query and executes it. SQL queries insecurely constructed from user input can be rewritten to perform unintended actions such as the disclosure of sensitive information.

The SQL injection discussed in this workshop is reviewed in [GHSA-79rg-7mv3-jrr5](https://github.com/advisories/GHSA-79rg-7mv3-jrr5) in [GitHub Advisory Database](https://github.com/advisories).

To find the SQL injection we are going to:

- Identify the vulnerable method discussed in the advisory and determine how it is used.
- Model the vulnerable method as a SQL sink so the SQL injection query is aware of this method.
- Identify how the vulnerable method can be used by finding new XWiki specific entrypoints.
- Model the new entrypoints as a source of untrusted data that can be used by CodeQL queries.
  
Once we have completed the above steps, we can see whether the models, our codified security knowledge, can uncover variants or possible
other security issues.

Let's start with finding more about the SQL injection.

### 1. Finding the insecure method

In the security advisory [GHSA-79rg-7mv3-jrr5](https://github.com/advisories/GHSA-79rg-7mv3-jrr5) in [GitHub Advisory Database](https://github.com/advisories) we learn of a [Jira issue](https://jira.xwiki.org/browse/XWIKI-17662) that discusses SQL injection in more detail.

From the Jira issue we learn that:

1. There exists a method `getAverageRating` in the _Rating Script Service_.
2. The two parameters of `getAverageRating` are used in the class `AbstractRatingManager` to insecurely construct a SQL statement.

We will use CodeQL to find the method and use the results to better understand how the SQL injection can manifest.

Select the database [xwiki-platform-ratings-api-12.8-db.zip] as the current database by right-clicking on it in the _Explorer_ and executing the command _CodeQL: Set current database_.

1. Find all the methods with the name `getAverageRating`
   <details>
   <summary>Hints</summary>
   - The `java` module provides a class `Method` to reason about methods in a program.
   - The class `Method` provides the member predicates `getName` and `hasName` to reason about the name of a method.
   </details>
2. Refine the set of results by limiting it to methods named `getAverageRating` where the first parameter is named `fromsql`.
   <details>
   <summary>Hints</summary>
   - The class `Method` provides the member predicate `getParameter` that expects an index to retrieve the corresponding parameter, if any.
   - The class `Parameter` provides the member predicates `getName` and `hasName` to reason about the name of a parameter.
   </summary>
3. Find all the methods with the name `getAverageRatingFromQuery`.
   <details>
   <summary>Hints</summary>
   - The `java` module provides a class `Method` to reason about methods in a program.
   - The class `Method` provides the member predicates `getName` and `hasName` to reason about the name of a method.
   </details>
4. Reduce the number of results by filtering uninteresting results.
   <details>
   <summary>Hints</summary>
   - The class `Method` provides the member predicates `getBody` to reason about the statements that constitute a method.
   - You can use the quantifier `exists` like `not exists(foo())` to determine if a predicate has no results.
   </details>

### 2. Identifying and modelling a SQL sink

Following the use of `sql`, we can see it is passed to a method `search`.
In the following exercises we are going to use CodeQL to investigate the `search` method.

1. Find all the calls to a method named `search`.
   <details>
   <summary>Hints</summary>
   - Calls to methods are method accesses. The class `MethodAccess` allows you to reason about method accesses.
   - The class `MethodAccess` provides a member predicate `getMethod` allows you to reason about the method being accessed.
   - The class `MethodAccess` provides the member predicates `getName` and `hasName` to reason about the name of a method.
   </details>
2. Find all the method accesses in the method `getAverageRatingFromQuery`.
   <details>
   <summary>Hints</summary>
   - The class `MethodAccess` provides the member predicate [getEnclosingCallable](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Expr.qll/predicate.Expr$MethodAccess$getEnclosingCallable.0.html) to reason about the method or constructor containing the method access.
   - The class [Callable](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/type.Member$Callable.html) provides the member predicates [getName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Element.qll/predicate.Element$Element$getName.0.html) and [hasName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Element.qll/predicate.Element$Element$hasName.1.html) to reason about the name of a method.
   </details>
3. Select the qualified name of the method `search`.
   <details>
   <summary>Hints</summary>
   - The class [Method](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/type.Member$Method.html) provides the member predicate [getQualifiedName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/predicate.Member$Member$getQualifiedName.0.html) useful fore debugging. The more efficient [hasQualifiedName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/predicate.Member$Member$hasQualifiedName.3.html) for restricting a method.
   </details>
4. Use the qualified name of the method `search` to uniquely identify it.
   <details>
   <summary>Hints</summary>
   - Use the `where` clause to restrict the results of the query.
   - The class [Method](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/type.Member$Method.html) provides the member predicate [getQualifiedName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/predicate.Member$Member$getQualifiedName.0.html) useful fore debugging. The more efficient [hasQualifiedName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/predicate.Member$Member$hasQualifiedName.3.html) for restricting a method.
   </details>
5. Transform the `select` clause into a class with the name `XWikiSearchMethod`
   <details>
   <summary>Hints</summary>
   - The steps for transforming a `select` clause into a class are:
      1. [Define a class](https://codeql.github.com/docs/ql-language-reference/types/#defining-a-class) and it's [characteristic predicate](https://codeql.github.com/docs/ql-language-reference/types/#characteristic-predicates). It will extend, through `extends`, from the class used in the `from` part of your [select clause](https://codeql.github.com/docs/ql-language-reference/queries/#select-clauses).
      2. Copy the `where` part from the [select clause](https://codeql.github.com/docs/ql-language-reference/queries/#select-clauses) into the [characteristic predicate](https://codeql.github.com/docs/ql-language-reference/types/#characteristic-predicates).
      3. Replace the variable with type the class `extends` from with the `this` variable.
      4. If the class relies on other variables from the `from` part then you can wrap the body of the characteristic predicate with an [exists](https://codeql.github.com/docs/ql-language-reference/formulas/#exists) quantifier to introduce those variable.
   </details>
6. Create the class `XWikiSearchSqlInjectionSink` that extends the `QueryInjectionSink` class to mark the first argument of a method access to the method `search`  a _sink_.
   <details>
   <summary>Hints</summary>
   - The `QueryInjectionSink` is a subclass of `DataFlow::Node`, so it represents a node in the dataflow graph.
     You can use the member predicate `asExpr` to find a corresponding AST node.
   - The class `Method` has a member predicate `getAReference`, that is inherited by our class `XWikiSearchMethod`, that provides all the method accesses targeting that method.
   - The class `MethodAccess` has a member predicate `getArgument()` that provided an index returns the nth argument provided to the method access.
   <details>

### 3 Attack surface and sources

You can copy [CheckPoint2.ql](java/sql-injection/src/checkpoints/CheckPoint2.ql) to continue.

1. Find all the method accesses of the method `search`.
   <details>
   <summary>Hints</summary>
   - You can reuse your class `XWikiSearchMethod`.
   - The class `Method` provides the member predicate `getAReference`, that is inherited by our class `XWikiSearchMethod`, providing all the method access of the method.
    </details>
2. Find all the classes that extend the abstract class `AbstractRatingsManager`.
   <details>
   <summary>Hints</summary>
   - The class `Class` represent all the classes in the program.
   - The class `Class` provides the member predicates `getName` and `hasName` to reason about the name of a class.
   - The class `Class` provides the member predicate `extendsOrImplements`  that holds if the provide type is an immediate super-type part of the `extends` or `implements` relationship.
   </details>
3. Write a query that finds classes annotated with `org.xwiki.component.annotation.Component` and implement the interface `org.xwiki.script.service.ScriptService`.
   <details>
   <summary>Hints</summary>
   - The class `Interface` represents all the Java interfaces in a program.
   - The class `Interface` provides the member predicates `getQualifedName` and `hasQualifiedName` to reason about the qualified name of an Java interface.
   - The class `Class` provides the member predicate `getAnAnnotation` to get the annotation that apply to the class.
   - User defined annotations are declared using an [annotation type](https://docs.oracle.com/javase/tutorial/java/annotations/declaring.html). The class `Annotation`, returned by `getAnAnnotation`, provides the member predicate `getType` to get the annotation type of an annotation.
   - The type `AnnotationType` is a specialization of an interface and allows us, among others, to reason about it's qualified name using the member predicates `getQualifiedName` and `hasQualifiedName`.
   </details>
4. Transform the `select` clause into the class `XWikiScriptableComponent`.
5. Write a class `XWikiScriptableComponentSource` that extends the class `RemoteFlowSource` and identifies parameters of the public methods defined in a scriptable component as sources of untrusted data.
   <details>
   <summary>Hints</summary>
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

   </details>

### 4. Variant analysis

With our fresh query we can now look if our freshly codified security knowledge can find variants.
Select the database [xwiki-platform-12.8-db.zip](xwiki-platform-12.8-db.zip) as the current database and re-run the query.
To get a good sense of the newly found variants, comment out the definition of the `XWikiScriptableComponentSource` and compare the differences in results.
