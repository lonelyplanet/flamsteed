module.exports = function(grunt) {
	'use strict';

	grunt.registerTask('echoJasmineUrl', 'Literally just spit out a url to the jasmine specrunner file.', function() {
		grunt.log.writeln('You can run your tests at the following url: \u001b[0;33mhttp://localhost:8888/_SpecRunner.html\u001b[0m');
	});
};