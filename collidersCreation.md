# STLやdaeで定義されている形状ベースでの干渉チェック用collider作成

Doosan A0509の第4リンクは形がストレートでないため、bounding boxベースで
colliderを作成すると適切な形状ができない。(Unitree G1等も同様)

そのため、一部のリンクについては、URDFと一緒に提供されているdae(またはSTL)から
形状を加工してcolliderを作成する。[`HowToMakeShapes_json_file3`](https://github.com/TSUSAKA-ucl/cd-config-generation/blob/main/docs/HowToMakeShapes_json_file3.md)も参照

Doosanは、形状のdaeファイルはmm単位の数値が入っていてurdfファイルの中
で記述してスケールしている。しかし**点群のdecimateや凸分解のパラメータは物理寸法
単位になるため大変都合が悪い**。そのため、collider作成手順は、形状
decimate経由の方法もbounding box経由の方法も、**最初に**形状を読み込むところに
scaleパラメータを指定できるようにして対応することとした。

urdf自体のリンク寸法の単位はSI(メートル)と決まっていてDoosamも
そのようになっているため、IKについては特に気にすることは無い。

一方、daeの不正スケール問題の影響を受けるA-Frameによる画面表示は、glTFの
スケールは1000倍のまま、urdfファイルに記述されているスケールを、A-Frameに
そのまま渡す方法を取った。手順の簡単化のためである。

その結果
* URDF(`urdf.json`): 特にスケール問題に関して気にすることは無い
* `linkmap.json`, `update.json`: scaleキーを元のURDFのまま残す
* glTF: URDFにスケールが書いてあれば、そのスケールに合ったサイズに拡大
* `shapes.json`: URDFでdae, STLがスケールされているようならば、
  それを通常の単位(SI)に戻すオプションを付けて生成する

以上の対応となった。今後いつか(未定)、colliderのvisualization用のglTF
は通常単位(SI)にスケールしたものを使うようにする(`update-stub.json`の
生成を変更する)。

daeの形状を加工してcolliderを作成する手順は以下のとおり。以下の`blender`は
ver.3.6が必要でver.4は使えない。

0. `CoACD`をソースビルド、`pymeshlab`をインストールする
   * `CoACD`  
     [`https://github.com/SarahWeiii/CoACD.git`](
     https://github.com/SarahWeiii/CoACD.git)
	 README.mdを読んでビルドする。ビルドしてできる`main`を使用する。
   * `pymeshlab`  
     ```
     python3 -m venv ~/venv
     source ~/venv/vin/activate
     pip install pymeshlab
     ```
1. `meshes`ディレクトリは既に作成済なはず。`A0509_4_0.dae`だけ形が悪い
   のでbboxと別の方法でcolliderを作成する
    ```
    cd meshes
    ```
2. meshをdecimateして頂点の数を減らす。
   今回は不要だったが、場合によってはパラメータの調整が必要になる。
   Doosanの場合daeが実際には1mm単位になっているので`--scale 0.001`必要。
   ```
   blender -b -P ../s/blender_decimate.py  -- --input A0509_4_0.dae --output A0509_4_0.out/ --scale 0.001
   ```
3. 
    ```
    cd A0509_4_0.out/
    ```
4. 頂点数を減らした形状を目視で確認する
    ```
    meshlab step03_decimated.stl 
    ```
5. `CoACD`が入力できるフォーマット: OBJ形式に変換する
    ```
    meshlabserver -i step03_decimated.stl -o step03_decimated.obj
    ```
6. 凸多面体に分解する(`CoACD`の`main`のpathは適当にする)
    ```
    ~/Test/CoACD/build/main -i step03_decimated.obj -o step03_decimated.wrl
    ```
7. 凸分解結果を目視確認する
    ```
    meshlab step03_decimated.wrl 
    ```
8. 凸分解結果を凸多面体毎に別々のファイルにする
    ```
    blender -b -P ../../s/split_CoACD_wrl.py 
    ```
9. どのようにバラバラになったかパーツ毎に表示・非表示にして目視確認する
    ```
    meshlab output_parts/*.ply
    ```
10. 
	```
	cd output_parts/
	```
11. 凸多面体の数を減らすために複数の凸多面体の和集合の凸包を作り一つの凸多面体にする。
    上記`meshlab`での目視確認の結果で適当に組み合わせる。この数を減らすと計算速度の
	向上が期待できる　
	```
	blender -b -P ../../../s/blender_convex_hull_multi.py -- convex_000.ply convex_001.ply convex_00from0to1.stl
	```
	```
	blender -b -P ../../../s/blender_convex_hull_multi.py -- convex_002.ply convex_003.ply convex_00from2to3.stl
	```
13. 凸多面体を少し膨らませる計算(`inflate_ply.py`)のためASCII PLY形式に変換
	```
	meshlabserver -i convex_00from0to1.stl -o convex_00from0to1.ply -m sa
	```
	```
	meshlabserver -i convex_00from2to3.stl -o convex_00from2to3.ply -m sa
	```
15. colliderとして使用するため5%膨らませる
	```
	python3 ../../../s/inflate_ply.py convex_00from0to1.ply convex_00from0to1-inflated.ply 1.05
	```
	```
	python3 ../../../s/inflate_ply.py convex_00from2to3.ply convex_00from2to3-inflated.ply 1.05
	```
17. 元の図形と膨らませた後と目視確認する
	```
	meshlab convex_00*from*.ply
	```
18. 3D形状を直接colliderに変換する部分は終わり
	```
	cd ../..
	```
19. その他のリンクは簡単にbounding boxベースでcollider作成する  
　	daeの単位が良くない件は、ここでも修正する(`-s 0.001`)
	```
	../s/boundingBoxScale.sh -s 0.001 A0509_*.dae
	```
	ここで`pymeshlab`を使用している。スケーリングしてbounding boxを計算するついでに
	スケーリングした形状のPLYファイルをexportしている。ros2 URDFはSTLかdaeを使用し
	plyは使用していないため好都合。
20. boundingbox(`.bbox`)から面取りをして凸多面体のcollider候補を作る
	```
	../s/createBboxAll.sh 
	```
21. スケーリングしたplyと面取りしたbounding boxを目視確認する。
	```
	for orig in *[0-9].ply; do meshlab "$orig" "${orig%.*}".bbox.ply; done
	```
22. ロボットのどのリンクにどのcolliderを付けるかの定義ファイル`shapeList.json`の
	雛形を作る
	```
	../s/create_shapelist.sh *.bbox.ply A0509_4_0.out/output_parts/*inflated.ply  >shapeList.json
	```
23. `shapeList.json`の**雛形は、そのままでは正しく使用できない**ので手動で編集する
	この時linkとcolliderの対応がわからない場合は`update.json`を見ると参考になる。
	ただし`update.json`は表示用の情報なので、あくまで参考。
	```
	vi shapeList.json
	```
24. ASCII PLY形式の各凸多面体のcolliderをまとめて`shapes.json`として使用可能な
	`output.json`を作る。この時URDFに記述してある必要な座標変換を施している
	```
	../s/ply_loader.js shapeList.json ../linkmap.json 
	```
25. リンクの数(+1)に対応した配列ができているかどうか確認する
	```
	../s/json-dimensions.py -d 2 output.json 
	```
26. ロボットアーム定義用のnpmパッケージの所定の場所にコピーする。
	コピー先ディレクトリは適宜変更する。
	```
	cp output.json ../GeneratedData/public/a0509/shapes.json 
	cp testPairs.json ../GeneratedData/public/a0509/
	```
	この2個のファイルがあれば、干渉チェックは動く。collider表示用のglTF作成に関しては
	省略
