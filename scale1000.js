const fs = require('fs');

/**
 * オブジェクト内のすべての数値を1/1000にする再帰関数
 */
function scaleNumbers(data) {
    if (typeof data === 'number') {
        return data / 1000;
    } else if (Array.isArray(data)) {
        return data.map(scaleNumbers);
    } else if (typeof data === 'object' && data !== null) {
        const newData = {};
        for (const key in data) {
            newData[key] = scaleNumbers(data[key]);
        }
        return newData;
    }
    return data;
}

const inputFilePath = 'shapes.json';   // 元のファイル
const outputFilePath = 'shapes-a1000th.json'; // 書き出し先ファイル

// 1. ファイルを読み込む
fs.readFile(inputFilePath, 'utf8', (err, jsonString) => {
    if (err) {
        console.error("ファイルの読み込みに失敗しました:", err);
        return;
    }

    try {
        // 2. JSONをパース（オブジェクトに変換）
        const data = JSON.parse(jsonString);

        // 3. 数値を変換
        const scaledData = scaleNumbers(data);

        // 4. JSON文字列に戻して保存 (整形用にインデント2を追加)
        const outputJson = JSON.stringify(scaledData, null, 2);
        
        fs.writeFile(outputFilePath, outputJson, 'utf8', (err) => {
            if (err) {
                console.error("ファイルの書き出しに失敗しました:", err);
                return;
            }
            console.log(`変換完了: ${outputFilePath} に保存しました。`);
        });

    } catch (parseErr) {
        console.error("JSONのパースに失敗しました:", parseErr);
    }
});
