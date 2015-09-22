module class

static def info = """
	This is multiline string.
	It automatically accepts all tabs, newlines
	and whitespace in general. Syntax for
	multiline strings is triple quotes for initializing,
	triple quotes for terminating
"""

static def main()
	trace(info)
	
	trace("""
		And this is inline multiline string.
		It also works.
	""")
end