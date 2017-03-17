#!/usr/bin/groovy

poms = 0
pomsPG = 0
pomsPA = 0
pomsPV = 0
pomsG = 0
pomsA = 0
pomsV = 0
orphans = 0
badList = []

"find . -name pom.xml".execute().text.eachLine() { pomPath ->
    poms += 1
    print "poms=" + poms.toString() + "\r"
    pom = new XmlSlurper().parse(pomPath)
    orphans += pom.parent == "" ? 1 : 0
    pomsPG += pom.parent.groupId != "" ? 1 : 0
    pomsPA += pom.parent.artifactId != "" ? 1 : 0
    pomsPV += pom.parent.version != "" ? 1 : 0
    pomsG += pom.groupId != "" ? (pom.parent == "" ? 0 : 1) : 0
    pomsA += pom.artifactId != "" ? 1 : 0
    pomsV += pom.version != "" ? (pom.parent == "" ? 0 : 1) : 0
    if (pom.groupId != "" || pom.version != "") {
        badList += ((pom.groupId != "") ? "grp " : "    ") + ((pom.version != "") ? "ver " : "    ") + pomPath
    }
}

println "poms=$poms orphans=$orphans pomsPG=$pomsPG pomsPA=$pomsPA pomsPV=$pomsPV pomsG=$pomsG pomsA=$pomsA pomsV=$pomsV"
println badList.join("\n")
