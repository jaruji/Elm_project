import { group, sleep } from 'k6';
import http from 'k6/http';

// Version: 1.2
// Creator: WebInspector

export let options = {
	maxRedirects: 0,
	stages: [
		// {
		// 	target : 50, duration : "30s"
		// },
		// {
		// 	target: 200, duration : "1m"
		// },
		// {
		// 	target : 100, duration : "30s"
		// },
		// {
		// 	target : 100, duration : "10s"
		// },
		// {
		// 	target : 200, duration : "20s"
		// },
		// {
		// 	target : 300, duration : "30s"
		// }
		// {
		// 	target : 50, duration : "10s"
		// },
		// {
		// 	target : 200, duration : "10s"
		// },
				{
			target : 250, duration : "8s"
		}
		]
};

export default function() {

	group("Global", function() {
		let req, res;
		req = [{
			"method": "get",
			"url": "http://localhost:3000/comment/get?id=03d8d5ec0b7c98329749",
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
			"url": "http://localhost:3000/image/info?id=03d8d5ec0b7c98329749",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"auth": "",
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
			"url": "http://localhost:3000/image?id=03d8d5ec0b7c98329749",
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
			"method": "options",
			"url": "http://localhost:3000/image/info?id=03d8d5ec0b7c98329749",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"Accept": "*/*",
					"Access-Control-Request-Method": "GET",
					"Access-Control-Request-Headers": "auth",
					"Origin": "http://localhost:8000",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/image/stats?id=03d8d5ec0b7c98329749",
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
		}];
		res = http.batch(req);
		sleep(0.59);
		req = [{
			"method": "get",
			"url": "http://localhost:3000/img/profile/5fb6ad087a2d164eb4e2501d.png",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9",
					"If-None-Match": "W/\"17b43-175e1a5b398\"",
					"If-Modified-Since": "Thu, 19 Nov 2020 17:55:34 GMT"
				}
			}
		}];
		res = http.batch(req);
		// Random sleep between 20s and 40s
		sleep(Math.floor(Math.random()*20+20));
	});

}
