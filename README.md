# `robot-loader` 用の Universal Robots Description の作成

以下の手順には、ROS2、blender3.6、meshlab/meshlabserver、および Node.js が必要です。<br>
ROS2 をインストールするには、公式の ROS2 インストールガイドを参照してください:
https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html
```
sudo apt update
sudo apt install ros-dev-tools
sudo apt install ros-jazzy-desktop-full
sudo apt install ros-jazzy-urdf-tutorial
```
以下の手順で使用される blender スクリプトは、ver.4 では正しく動作しない可能性があります。<br>
ver.3.6 をインストールしてください。<br>
そして、必要に応じて環境変数 `BLENDER` を blender 実行可能ファイルへのパスに設定してください。<br>
例えば、
```
× export BLENDER=~/Downloads/blender-3.6.4-linux-x64/blender
export BLENDER=~/blender/blender
```
blender をインストールするには、公式ウェブサイトを参照してください。:
https://www.blender.org/download/lts/3-6/

Meshlab と meshlabserver は apt を使用してインストールできます。:
```
sudo apt install meshlab
```

## robot-loader および ik-worker で使用されるジョイント情報とリンクの可視化情報の作成

このセクションでは、Doosan Robotics ロボットを `robot-loader` および `ik-worker` で使用するために必要な `urdf.json`、`linkmap.json`、`update.json` ファイル、およびメッシュファイルの作成方法について説明します。

0. ros2 ワークスペースがない場合は作成します。**上書きは不可です。**
   ```
   mkdir -p ~/ros2_ws/src
   cd ~/ros2_ws
   colcon build
   ```

1. UR git リポジトリを ros2 ワークスペースの `src` フォルダにクローンします。
   ```
   cd src
   git clone https://github.com/doosan-robotics/doosan-robot2.git -b jazzy
   apt-get update
   rosdep update
   rosdep install -y -i --from-paths ./doosan-robot2/dsr_hardware2/ ./doosan-robot2/dsr_msgs2/
   ./doosan-robot2/dsr_controller2/ ./doosan-robot2/dsr_description2/
   cd -
   ```

2. ros2 ワークスペースをビルドします。
   ```
   source /opt/ros/jazzy/setup.bash
   colcon build --packages-select dsr_msgs2 dsr_description2 dsr_controller2 dsr_hardware2
   . install/setup.bash
   ```

3. `display.launch.py` を起動して UR ロボットの設定を確認します (オプション)。
   ```
   ros2 launch urdf_tutorial display.launch.py model:=$PWD/src/doosan-robot2/dsr_description2/urdf/a0509.urdf
   ```
   Joint State Publisher を使用して RViz 内でロボットを動かすことができます。<br>
   ロボットのジョイントのゼロ位置と各ジョイントの動きの方向を確認することをお勧めします。

4. xacro を使用して ROS URDF ファイルを作成します。
   ```
   xacro `ros2 pkg prefix dsr_description2`/share/dsr_description2/xacro/a0509.urdf.xacro color:=white > a0509_robot.urdf
   ```

5. この作業ディレクトリに戻り、まだの場合はスクリプトの[リポジトリ](https://github.com/ymucystk/A0509-example)をクローンします。<br>
   **※ 前ステップで生成した ROS URDF ファイルをこの作業ディレクトリにコピーします。**
   ```
   mv a0509_robot.urdf <this_working_directory>
   ```
   ```
   cd <this_working_directory>
   rm -rf gjk_worker
   rm -rf robot-assets
   ```
   ```
   ./clone.sh
   pnpm i yargs
   ```

5. `splitUrdfTree.sh` スクリプトを使用して、URDF ツリーを個別のチェーンに分割します。
   ```
   ./a/splitUrdfTree.sh a0509_robot.urdf
   ```

6. 対応する `chain_X.json`(概要) ファイルを調べて、必要な `chain_X.urdf` ファイルを選択します。<br>
   `ls -l chain_*.json` を使用して各チェーンファイルのサイズを確認し、`view chain_0.json` で最長のチェーンの詳細を確認します。<br>
   通常、最長のチェーンが主要なロボットボディに対応します。<br>
   必要なルートリンクとエンドエフェクタリンクが含まれている場合は、それを選択します。

7. 選択した `chain_X.urdf` ファイルから、`extract-joint-and-link-tag.sh` を使用して、
   ジョイントマップファイル (`urdf.json`)、リンクマップファイル (`links.json`)、およびモディファイアファイル (`update.json`) を生成します。<br>
   例えば、`chain_0.urdf` が選択された場合は、以下を実行します。
   ```
   ./a/extract-joint-and-link-tag.sh chain_0.urdf
   ```
   これにより、`urdfmap.json` (または `urdfsorted.json`)、`linkmap.json`、および `update-stub.json` ファイルが生成されます。

8. `./a/cut-joint-map.sh` スクリプトを使用して、`urdfmap.json` からジョイントマップの不要な部分を切り取ります。<br>
   例えば、`chain_0.urdf` が選択された場合は、以下を実行します。
   ```
   ./a/cut-joint-map.sh urdfmap.json --from base_link --to link_6
   ```
   `--from` および `--to` オプションは、選択されたチェーンのルート **LINK** とエンドエフェクタ **link** を指定します。<br>
   これにより `urdfmap_cut.json` ファイルが生成されます

9. 切り取られたジョイントマップファイル (`urdf.json`)を使用してリンクマップファイル (`links.json`)を再生成します。<br>
   例えば、`chain_0.urdf` が選択された場合は、以下を実行します。
   ```
   ./a/extract-joint-and-link-tag.sh chain_0.urdf -j urdfmap_cut.json
   ```
   これは厳密には必要ではありませんが、より小さな `linkmap.json` および `update-stub.json` ファイルが生成され、`update-stub.json` ファイルの編集が容易になります。<br>
   コライダーの形状を可視化しない場合は、`-n` オプションを使用できます。

10. リンクマップファイル (`links.json`)から可視化と衝突に必要な形状データを見つけます。
    ```
    Meshes=(`grep filename linkmap.json |sed 's/^\s*//'| sed -e 's/^[^:]*:\s*//' -e 's/"//g' -e 's/,//'|sort -u |grep -v collision`);for path in "${Meshes[@]}"; do echo $path; done
    ```
    これにより、選択されたチェーンで使用されているすべてのメッシュファイルの ROS2 パスが一覧表示されます。<br>
    ros2 ワークスペースでロボットのディスクリプションパッケージをビルドしていた場合、パスは `install` フォルダの下で見つけることができます。<br>
    そうでない場合は、通常、ステップ 1 でクローンしたソースツリー内で見つけることができます。

11. メッシュファイルを `meshes` フォルダにシンボリックリンクまたはコピーします。**上書き不可です。**<br>
   クローン直後の状態で既に`meshes` フォルダがある場合は`meshes_org` 等にリネームして退避します。<br>
    例えば、
    ```
    mkdir -p meshes
    cd meshes
    ```
    <!--`CONVUM_SGE-M5-N-body-m.bbox` `CONVUM_SGE-M5-N-suction-m.bbox` `table.ply` `template.mlp` をコピーします。-->
    `table.ply` `template.mlp` を`meshes` フォルダにコピーします。
    ```
    cp ../meshes_org/table.ply ./
    cp ../meshes_org/template.mlp ./
    ```
    ```
    DSRDir=`ros2 pkg prefix dsr_description2`/share/dsr_description2
    ```
    以下、コピーを実行します。
    ```
    for path in "${Meshes[@]}"; do
      path=`echo $path | sed 's|^package://dsr_description2/||'`
      ln -s $DSRDir/$path .
    done
    ```

12. `convert-to-gltf.sh` ツールを使用してメッシュを glTF 形式に変換します。
    ```
    for file in *.STL *.stl *.DAE *.dae; do
      ../a/convert-to-gltf.sh "$file"
    done
    cd ..
    ```
    これにより、`out` フォルダの下に各メッシュファイルの glTF ファイル (`.gltf` および `.bin`) が生成されます。

13. `json-pretty-compact.sh` ツールを使用してコンパクトな `update.json` を作成します。
    ```
    ./a/json-pretty-compact.sh update-stub.json -o update.json -c 90
    ```
    そして、必要に応じて `update.json` を編集します。


14. 最後に、`urdfmap_cut.json` を `urdf.json` に名前変更し、`urdf.json`、`linkmap.json`、`update.json`、および `meshes/out/` フォルダ内のファイルを `public/a0509/` フォルダまたは他の任意の希望のフォルダに移動します。<br>
    ```
    mkdir -p ./public/a0509
    cp urdfmap_cut.json ./public/a0509/urdf.json
    cp linkmap.json ./public/a0509/linkmap.json
    cp update.json ./public/a0509/update.json
    cp -r meshes/out/*.* ./public/a0509/
    ```
    これで、作成されたファイル (`urdf.json`、`linkmap.json`、`update.json`) および glTF メッシュファイルを `robot-loader` および `ik-worker` とともに使用できます

## コライダー情報とその可視化情報の作成

このセクションでは、`cd-worker` で使用されるコライダーを定義する `shapes.json` ファイルと可視化情報の作成方法について説明します。

`shapes.json` ファイルは、凸形状の頂点とそれらの構成のみを定義します。

`shapes.json` ファイルを作成するには 2 つの方法があります。

1 つはリンクメッシュのバウンディングボックスから作成する方法で、もう 1 つはより複雑で、リンクメッシュをデシメートして凸状のパーツに分解する方法です。

前者の方法については、[`HowToMakeShapes_json_file2.md`(in Japanese)](https://github.com/TSUSAKA-ucl/cd-config-generation/blob/main/docs/HowToMakeShapes_json_file2.md)を参照してください。
後者の方法については、[`HowToMakeShapes_json_file3.md`(in Japanese)](https://github.com/TSUSAKA-ucl/cd-config-generation/blob/main/docs/HowToMakeShapes_json_file3.md)を参照してください。

Doosan Robotics ロボットは単純な形状のリンクを持っているため、通常は前者の方法で十分です。

1. DAE ファイルを使用してバウンディングボックスからコライダーを作成します。
   ```
   cd meshes/
   ../s/boundingBox.sh *.dae
   ```
   これにより、各 DAE ファイルの `.bbox` ファイルが作成されます。

2. 必要に応じてバウンディングボックスファイルを編集して、よりタイトにします

3. バウンディングボックスファイルからコライダー用のコライダーファイル (STL ファイル、PLY ファイル、glTF ファイル) を作成します。
   ```
   ../s/createBboxAll.sh
   ```

4. 生成されたコライダーが許容できるか確認します。**（GUI画面が開くので形状を確認）**<br>
   `meshlab` はコマンドラインから DAE ファイルを直接開く際に問題があるため、プロジェクトファイルを作成して開く必要がある場合があります。
   ```
   for dae in *.dae
   do sed -e "s/TEMPLATE/${dae%.*}/g" template.mlp > "${dae%.*}.mlp"
      meshlab "${dae%.*}".mlp
   done
   ```
   ROS の可視化が DAE ファイルの代わりに STL ファイルを使用する場合、meshlab のプロジェクトファイルは必要ありません。
   2 つの STL ファイルを直接開くことができます

5. すべてのコライダーが許容できる場合は、各リンクのコライダーファイルを一覧表示する `shapeList.json` ファイルを作成します。
   ```
   ../s/create_shapelist.sh *.bbox.ply > shapeList.json
   ```

6. `urdf.json` のジョイントの順序に従ってリンクを並べ替えるために `shapeList.json` を編集します。<br>
   さらに、必要に応じて、エンドリンクに固定されたツールとベースプレートのコライダーを追加します。:
   ```
   [
      [ "table.ply", "A0509_0_0.bbox.ply" ],
      [ "A0509_1_0.bbox.ply" ],
      [ "A0509_1_1.bbox.ply" ],
      [ "A0509_1_2.bbox.ply" ],
      [ "A0509_2_0.bbox.ply" ],
      [ "A0509_2_1.bbox.ply" ],
      [ "A0509_2_2.bbox.ply" ],
      [ "A0509_3_0.bbox.ply" ],
      [ "A0509_3_1.bbox.ply" ],
      [ "A0509_4_0.bbox.ply" ],
      [ "A0509_4_1.bbox.ply" ],
      [ "A0509_5_0.bbox.ply" ],
      [ "A0509_5_1.bbox.ply" ],
      [ "A0509_6_0.bbox.ply" ]
   ]
   ```

7. `shapeList.json` から `shapes.json` ファイルを作成します。
   ```
   ../s/ply_loader.js shapeList.json ../linkmap.json
   ```
   これにより `output.json` ファイルが生成されます。以下のコマンドで`shapes.json` に名前を変更します。
   ```
   mv output.json shapes.json
   ```
   これで、A0509 ロボットのコライダーを定義する `shapes.json` ファイルができました。

8. リンク間の衝突検出をテストするための `testPairs.json` ファイルを作成します。<br>
   どのリンクペアを衝突テストすべきかを自動的に判断するのは難しいため、このファイルは手書きです。<br>
   ただし、多くの 6-DOF シリアルロボットの場合、以下のペアで十分です。:
   ```json
   [
     [0,2],[0,3],[0,4],[0,5],[0,6],[0,7],
     [1,3],[1,4],[1,5],[1,6],[1,7],
     [2,4],[2,5],[2,6],[2,7],
     [3,5],[3,6],[3,7]
   ]
   ```

9. 最後に、`shapes.json` と `testPairs.json` を `public/a0509/` フォルダまたは他の任意の希望のフォルダに移動します。<br>
    ```
    cp ./shapes.json ../public/a0509/
    cp ../testPairs.json ../public/a0509/
    ```
   これら`shapes.json` と `testPairs.json`は `cd-worker` が必要とするすべてです。<br>
   ただし、`robot-loader` でコライダーを可視化したい場合は、コライダー用の glTF ファイルも必要です。

10. コライダーの STL ファイルからコライダー用の glTF ファイルを作成します。 (`cd meshes/`)
    ```
    for file in *.bbox.stl; do
      ../a/convert-to-gltf.sh "$file"
    done
    ```
    STL には色情報がないため、`set-gltf-color.mjs` ツールを使用して glTF ファイルに色と不透明度を追加します。
    ```
    cd out
    for f in *.bbox.gltf; do
      node ../../s/set-gltf-color.mjs "$f" --color '#ffff00' --opacity 0.2
    done
    cd ../..
    ```
	`meshes/out/` フォルダで生成された glTF ファイルと bin ファイルを `public/a0509/` フォルダまたは他の任意の希望のフォルダに移動します。

<!--11. 必要に応じて、ツールのコライダーを描画するために `update.json` を修正します。<br>
      ```
      node ./addToolColliders.js
      ```
	又は<br>
      ```
      node ./addToolColliders.js update.json wrist_3_link CONVUM_SGE-M5-N-body-m.bbox.gltf CONVUM_SGE-M5-N-suction-m.bbox.gltf
      ```
	これらのコマンドは同じ `update_with_tool.json` ファイルを作成し、その後 `json-pretty-compact.sh` ツールを使用してコンパクトな `update.json` を作成（上書き）します。<br>
      ```
      ./a/json-pretty-compact.sh update-with-tools-collider.json -o update.json
      ```

	**注記:**
	ツールは `linkmap.json` で定義されていないため、アタッチされている **LINK の座標系 内** の形状として `shapes.json` および `update.json` に書き込まれます。これは、リンクの **glTF ビジュアルの原点 ではありません**。-->

これで、作成された `shapes.json`、`testPairs.json`、`newupdate.json` ファイル、およびコライダー glTF ファイル (`./meshes/out/*.bbox.gltf`) を `cd-worker` および `robot-loader` とともに使用できます。

ROS ロボットディスクリプションパッケージに可視化用の DAE ファイルが含まれておらず、可視化用に STL ファイルのみが含まれている場合は、前述のように `set-gltf-color.mjs` ツールを使用してコライダー glTF ファイルに色を追加できます。

## メッシュファイルの妥当性確認アプリのインストール

[こちらのリポジトリ](https://github.com/TSUSAKA-ucl/robot-loader-nextjs-example.git) に書いてある手順を実施します。
```
pnpm create next-app@latest
cd <project-directory>
```
リポジトリ内の`.npmrc`ファイルを`<project-directory>`にコピーします。<br>
リポジトリ内の`app`フォルダ内の`page.tsx`、`App.tsx`、`globals.css`ファイルを`<project-directory>`の`app`フォルダにコピーします。<br>
コピーした`App.tsx`ファイル内の`ur5e`の記述を`a0506`に変更します。(3か所)<br><br>
パッケージのインストールをします。
```
pnpm add aframe
pnpm add @ucl-nuee/robot-loader @ucl-nuee/ik-cd-worker
```
アセットコピースクリプトを実行して必要なアセットをパブリックフォルダにコピーします。
```
npx copy-assets
```
サーバーを構築して実行します。
```
pnpm build
pnpm dev
```

## コライダーの形状調整

任意のテキストエディターで .bbox ファイルを編集します。<br>
Mesh Bounding Box Size の行の値を小さくすると小さくなります。<br>
Mesh Bounding Box crop の行を追加することで、±どちらの方向に小さく(大きく)するかがコントロールできます。<br>
Mesh Bounding Box scale の行を追加することで、面取りの大きさをコントロールできます。<br>
