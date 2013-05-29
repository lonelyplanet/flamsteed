module.exports = function(grunt) {
	'use strict';

	// Project configuration.
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),

		coffee: {
			compile: {
				files: {
					'spec/javascripts/flamsteed_spec.js': 'spec/coffeescripts/flamsteed_spec.coffee',
					'spec/javascripts/support/spec_helper.js': 'spec/coffeescripts/support/spec_helper.coffee'
				}
			}
		},
		connect: {
			server: {
				options: {
					port: 8888
				}
			}
		},
		jasmine: {
			flamsteed: {
				src: 'lib/javascripts/flamsteed.js',
				options: {
					helpers: 'spec/javascripts/support/spec_helper.js',
					host: 'http://localhost:8888/',
					specs: 'spec/javascripts/flamsteed_spec.js'
				}
			}
		},
		watch: {
			scripts: {
				files: ['spec/coffeescripts/flamsteed_spec.coffee', 'spec/coffeescripts/support/spec_helper.coffee'],
				tasks: ['coffee', 'jasmine:flamsteed:build'],
				options: {
					nospawn: true
				}
			}
		}
	});

	grunt.loadTasks('grunt-tasks');

	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-connect');
	grunt.loadNpmTasks('grunt-contrib-jasmine');
	grunt.loadNpmTasks('grunt-contrib-watch');

	// Default task.
	grunt.registerTask('default', ['coffee', 'connect', 'jasmine']);
	grunt.registerTask('dev', ['coffee', 'connect', 'jasmine:flamsteed:build', 'echoJasmineUrl', 'watch']);
};