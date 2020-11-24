import { group, sleep } from 'k6';
import http from 'k6/http';

// Version: 1.2
// Creator: WebInspector

export let options = {
	maxRedirects: 0,
	// stages: [
	// 	{
	// 		target : 500, duration : "30s"
	// 	},
	// 	{
	// 		target: 1000, duration : "1m"
	// 	},
	// 	{
	// 		target : 500, duration : "30s"
	// 	},
	// 	]
	stages: [
		{
			target : 1000, duration : "10s"
		},
		{
			target : 2500, duration : "20s"
		},
		{
			target : 3000, duration : "30s"
		}
		]
};

export default function() {

	group("page_5 - http://localhost:8000/", function() {
		let req, res;
		req = [{
			"method": "get",
			"url": "http://localhost:8000/",
			"params": {
				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"Cache-Control": "max-age=0",
					"Upgrade-Insecure-Requests": "1",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
					"Sec-Fetch-Site": "same-origin",
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

				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Sun, 22 Nov 2020 09:27:22 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"cf12e-175ef4782a4\"",
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
			"url": "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/fonts/glyphicons-halflings-regular.woff2",
			"params": {
				"headers": {
					"Origin": "http://localhost:8000",
					"Referer": "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:8000/assets/carousel/1.jpg",
			"params": {

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
			"url": "http://localhost:3000/img/03d8d5ec0b7c98329749.png",
			"params": {

				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"If-Modified-Since": "Thu, 19 Nov 2020 18:19:49 GMT",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"If-None-Match": "W/\"7d554-175e1bbe5d6\"",
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
			"url": "http://localhost:8000/assets/favicon/favicon-32x32.png",
			"params": {

				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"Pragma": "no-cache",
					"Cache-Control": "no-cache",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
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
			"url": "ws://localhost:8000/",
			"params": {

				"headers": {
					"Pragma": "no-cache",
					"Origin": "http://localhost:8000",
					"Accept-Encoding": "gzip, deflate, br",
					"Host": "localhost:8000",
					"Accept-Language": "en-US,en;q=0.9",
					"Sec-WebSocket-Key": "TeQlPj//W8naTqnjWnBLUA==",
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
		sleep(4.48);
		req = [{
			"method": "get",
			"url": "http://localhost:8000/assets/carousel/2.jpg",
			"params": {

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
		sleep(6.00);
		req = [{
			"method": "get",
			"url": "http://localhost:8000/assets/carousel/3.jpg",
			"params": {

				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-origin",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9",
					"If-None-Match": "W/\"443d8-175e1570922\"",
					"If-Modified-Since": "Thu, 19 Nov 2020 16:29:38 GMT"
				}
			}
		}];
		res = http.batch(req);
		sleep(6.00);
		req = [{
			"method": "get",
			"url": "http://localhost:8000/assets/carousel/4.jpg",
			"params": {

				"headers": {
					"Host": "localhost:8000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-origin",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9",
					"If-None-Match": "W/\"35c11-175e1570926\"",
					"If-Modified-Since": "Thu, 19 Nov 2020 16:29:38 GMT"
				}
			}
		}];
		res = http.batch(req);
		// Random sleep between 20s and 40s
		sleep(Math.floor(Math.random()*20+20));
	});

}
