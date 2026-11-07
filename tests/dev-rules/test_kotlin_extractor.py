from package_map.extractors import Declaration, Member, for_extension
from package_map.extractors.kotlin import extract


def test_registered_for_kotlin_extensions():
    assert for_extension("kt") is not None
    assert for_extension("kts") is not None
    assert for_extension("txt") is None


def test_reads_package_and_import_packages():
    facts = extract(
        "package a.p\n"
        "\n"
        "import b.q.Thing\n"
        "import b.q.Thing.Nested\n"
        "import c.d.topFn\n"
        "import e.f.*\n"
        "import g.h.Type as Alias\n"
    )

    assert facts.package == "a.p"
    assert facts.imports == ("b.q", "b.q", "c.d", "e.f", "g.h")


def test_top_level_declarations_keep_kind_and_name():
    facts = extract(
        "internal data class State(val x: Int)\n"
        "fun interface Callback {\n"
        "    fun call()\n"
        "}\n"
        "internal fun <T> Box.extension(value: T) = value\n"
        "val Int.isEven: Boolean get() = this % 2 == 0\n"
        '@Suppress("LongMethod")\n'
        "internal const val LIMIT = 50\n"
        "typealias Id = String\n"
    )

    assert [(d.kind, d.name) for d in facts.declarations] == [
        ("internal data class", "State"),
        ("fun interface", "Callback"),
        ("internal fun", "extension"),
        ("val", "isEven"),
        ("internal const val", "LIMIT"),
        ("typealias", "Id"),
    ]


def test_private_declaration_is_file_private():
    facts = extract("private class P\nprivate fun helper() = 1\nfun open() = 1\n")

    assert [d.file_private for d in facts.declarations] == [True, True, False]


def test_reads_a_one_letter_name():
    facts = extract("class A\n")

    assert facts.declarations == (Declaration("class", "A"),)


def test_exposed_members_of_a_class():
    facts = extract(
        "class Box(\n"
        "    val width: Int,\n"
        "    private val secret: Int,\n"
        ") {\n"
        "    fun area(): Int = width\n"
        '    internal val label: String get() = ""\n'
        "    suspend fun load() = Unit\n"
        "    private fun hidden() = 1\n"
        "    protected fun guarded() = 2\n"
        '    override fun toString() = ""\n'
        "    companion object {\n"
        "        fun make() = Box(1, 2)\n"
        "    }\n"
        "}\n"
    )

    assert facts.declarations[0].members == (
        Member("val", "width"),
        Member("fun", "area"),
        Member("internal val", "label"),
        Member("suspend fun", "load"),
    )


def test_members_belong_only_to_their_own_class():
    facts = extract(
        "class First {\n"
        "    fun one() = 1\n"
        "}\n"
        "private class P {\n"
        "    fun notExposed() = 1\n"
        "}\n"
        "fun topLevel() {\n"
        "    val local = 1\n"
        "}\n"
    )

    first, private, top_level = facts.declarations
    assert first.members == (Member("fun", "one"),)
    assert private.members == ()
    assert top_level.members == ()


def test_constructor_properties_on_the_class_line():
    facts = extract("data class Point(val x: Int, private val y: Int, internal var z: Int, w: Int)\n")

    assert facts.declarations[0].members == (
        Member("val", "x"),
        Member("internal var", "z"),
    )
