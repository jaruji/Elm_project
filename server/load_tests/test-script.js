import { group, sleep } from 'k6';
import http from 'k6/http';

// Version: 1.2
// Creator: WebInspector

export let options = {
	maxRedirects: 0,
	stages: [
	{
		target : 50, duration : "30s"
	},
	{
		target: 150, duration : "1m"
	}
	]
};

export default function() {

	group("page_12 - http://localhost:8000/", function() {
		let req, res;
		req = [{
			"method": "get",
			"url": "http://localhost:8000/",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"Cache-Control": "max-age=0",
					"Upgrade-Insecure-Requests": "1",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
					"Sec-Fetch-Site": "none",
					"Sec-Fetch-Mode": "navigate",
					"Sec-Fetch-User": "?1",
					"Sec-Fetch-Dest": "document",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:8000/reload/reload.js",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "*/*",
					"Sec-Fetch-Site": "same-origin",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "script",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css",
			"params": {
				"headers": {
					"Referer": "http://localhost:8000/",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:8000/elm.js",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 16:54:16 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"cf12e-175e16d935c\"",
					"Accept": "*/*",
					"Sec-Fetch-Site": "same-origin",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "script",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/account/auth",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"auth": "75b521307b96217bddcdf648f13b38c60191fa82dc1e3359e3c0d034b5285e88e4d39a2730cb75f4b8269221338704dd",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/fonts/glyphicons-halflings-regular.woff2",
			"params": {
				"headers": {
					"Referer": ""
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/tags/trending",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/posts/latest",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/img/profile/5fb6ad087a2d164eb4e2501d.png",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 17:55:34 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"17b43-175e1a5b398\"",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/fonts/glyphicons-halflings-regular.woff2",
			"params": {
				"headers": {
					"Referer": ""
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:8000/assets/carousel/1.jpg",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 16:29:38 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"25f07-175e1570922\"",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-origin",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/fonts/glyphicons-halflings-regular.woff2",
			"params": {
				"headers": {
					"Referer": ""
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/img/f898b05f61a4ac51400b.png",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 17:55:00 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"17b43-175e1a53078\"",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/img/3decce0a5d4bcef443f3.png",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 17:54:49 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"e507-175e1a50585\"",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/img/960c41421a47a16242f7.png",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 17:51:45 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"bf12-175e1a23673\"",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/img/0383bb350caf497d1fc9.png",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 17:50:44 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"1042c-175e1a1461b\"",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/img/07e92a556e4b5e23cb9d.png",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 17:58:54 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"7d554-175e1a8c25e\"",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/fonts/glyphicons-halflings-regular.woff2",
			"params": {
				"headers": {
					"Referer": ""
				}
			}
		},{
			"method": "get",
			"url": "ws://localhost:8000/",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Pragma": "no-cache",
					"Origin": "http://localhost:8000",
					"Accept-Encoding": "gzip, deflate, br",
					"Host": "localhost:8000",
					"Accept-Language": "en-US,en;q=0.9",
					"Sec-WebSocket-Key": "vqtsa6ei/mYGNeMzuqAxmw==",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Upgrade": "websocket",
					"Sec-WebSocket-Extensions": "permessage-deflate; client_max_window_bits",
					"Cache-Control": "no-cache",
					"Connection": "Upgrade",
					"Sec-WebSocket-Version": "13"
				}
			}
		}];
		res = http.batch(req);
		sleep(4.52);
		req = [{
			"method": "get",
			"url": "http://localhost:8000/assets/carousel/2.jpg",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 16:29:38 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"22663-175e1570922\"",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-origin",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		}];
		res = http.batch(req);
		// Random sleep between 20s and 40s
		sleep(Math.floor(Math.random()*20+20));
	});

}
