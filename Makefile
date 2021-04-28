.PHONY: format
format:
	@swift format \
		--recursive \
		--in-place \
		--ignore-unparsable-files \
		./Sources/ \
		./Tests/ \
		./Package.swift
